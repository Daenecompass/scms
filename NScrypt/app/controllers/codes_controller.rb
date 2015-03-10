class CodesController < ApplicationController
  before_action :set_code, only: [:show, :edit, :update, :destroy]

  # GET /codes
  # GET /codes.json
  def index
    if params.has_key?(:contract_id)
      @codes = Code.where(contract_id: params[:contract_id])
    else
      @codes = Code.where("author = ? AND state <> 'Signed'", session[:user_id])
      Party.where("user_id = ?", session[:user_id]).each{ |p|
        @codes << p.code if p.code.proposed == 't' && p.code.author != session[:user_id]
      }
    end
    @codes = @codes.sort{ |a, b| b <=> a }
  end

  # GET /codes/1
  # GET /codes/1.json
  def show
  end

  # GET /codes/new
  def new
    @code = Code.new
  end

  # GET /codes/1/edit
  def edit
  end

  # POST /codes
  # POST /codes.json
  def create
    @code = Code.new(code_params)
    @code.author = session[:user_id]
    @code.state = 'Unassigned'
    @code.sign_state = 'Unsigned'
    @code.assign_state = 'Unassigned'
    @code.proposed = false
    @code.posted = false
    process_code(@code)
    respond_to do |format|
      if @code.save
        format.html { redirect_to @code, notice: 'Draft was successfully created.' }
        format.json { render :show, status: :created, location: @code }
      else
        format.html { render :new }
        format.json { render json: @code.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /codes/1
  # PATCH/PUT /codes/1.json
  def update
    respond_to do |format|
      if @code.update(code_params)
        process_code(@code)
        format.html { redirect_to @code, notice: 'Code was successfully updated.' }
        format.json { render :show, status: :ok, location: @code }
      else
        format.html { render :edit }
        format.json { render json: @code.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /codes/1
  # DELETE /codes/1.json
  def destroy
    @code.destroy
    respond_to do |format|
      format.html { redirect_to codes_url, notice: 'Code was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def propose
    @code = Code.find(params[:code_id])
    @code.proposed = true
    @code.save
    logger.info("Proposing code to counter-parties")
    redirect_to @code, notice: 'Code was submitted to counter-party(ies)'
  end

  def duplicate
    if params.has_key?(:code_id)
      old_code = Code.find(params[:code_id])
      new_code = Code.new
      new_code.author = session[:user_id]
      new_code.code = old_code.code
      new_code.contract_id = old_code.contract_id
      process_code(new_code)
      new_code.save
      respond_to do |format|
        format.html { redirect_to new_code, notice: 'Code was successfully duplicated.' }
        format.json { head :no_content }
      end
    end
  end

  def update_state
    if @code.nil?
      if params.include?(:party_id)
        @code = Party.find(params[:party_id]).code
      elsif params.include?(:code_id)
        @code = Code.find(params[:code_id])
      else
        raise "Something went wrong"
      end
    end

    set_assign_state
    set_sign_state
    set_code_state
    redirect_to @code
  end

  def set_assign_state
    parties = Party.where(code_id: @code.id)
    author = nil
    counterparties = Array.new
    assigned = Array.new
    unassigned = Array.new
    parties.each{ |p|
      if p.user.nil?
        unassigned << p
        if @code.author == p.user_id
          author = p
        else
          counterparties << p
        end
      else
        assigned << p
      end
    }

    code_assign_state = nil
    if assigned.length == parties.length
      code_assign_state = 'Assigned'
      logger.info("All roles are assigned")
    elsif !author.nil?
      code_assign_state = 'Self-assigned'
      logger.info("Self-Assigning author")
    elsif assigned.length == counterparties.length
      #code_assign_state = 'Counter-assigned'
      logger.info("Counter-assigning counterparty(ies)...")
      ### NOTE: Implying the author as the last remaining party--Must be a party to one's own contract
      logger.info("Assigning author to last remaining role")
      unassigned.first.user_id = @code.author
      unassigned.first.save
      code_assign_state = 'Assigned'
    else
      code_assign_state = 'Unassigned'
      logger.info("No assignments")
    end
    @code.assign_state = code_assign_state
    @code.save
  end

  def set_sign_state
    parties = Party.where(code_id: @code.id)
    author = nil
    counterparties = Array.new
    signed = Array.new
    parties.each{ |p|
      signed << p if p.state == 'Signed'
      if @code.author == p.user_id
        author = p
      else
        counterparties << p
      end
    }

    code_sign_state = 'Unsigned'
    if signed.length == parties.length
      code_sign_state = 'Signed'
    elsif author.state == 'Signed'
      code_sign_state = 'Pre-signed'
    elsif signed.length == counterparties.length
      code_sign_state = 'Counter-signed'
    end

    @code.sign_state = code_sign_state
    @code.save

    if code_sign_state == 'Signed'
      @code.contract.signed_code_id = @code.id
      if !@code.sc_event_id.nil?
        @code.contract.sc_event_id = @code.sc_event_id
      end
      @code.contract.save
      value = ScValue.new
      value.contract = @code.contract
      value.key = 'Signature Date'
      value.value = Time.now
      value.save
    end
  end

  def set_code_state
    sign_state = @code.sign_state
    assign_state = @code.assign_state
    posted = @code.posted
    proposed = @code.proposed
    code_state = nil

    if sign_state == 'Signed'
      code_state = 'Signed'
    elsif sign_state == 'Counter-signed' && proposed == "t"
      code_state = 'Counter-signed'
    elsif sign_state == 'Pre-signed'
      if proposed == "t"
        code_state = 'Offer'
      elsif posted == "t" && assign_state == 'Self-assigned'
        code_state = 'Open Offer'
      else
        code_state = 'Pre-signed'
      end
    elsif sign_state == 'Unsigned'
      if proposed == "t"
        code_state = 'Proposed'
      else
        code_state = assign_state
      end
    end

    if !code_state.nil?
      @code.state = code_state
      @code.save
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_code
    @code = Code.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def code_params
    params.require(:code).permit(:version, :code, :contract_id)
  end

  def process_code(code)
    if params.include?(:code)
      @code.code = Template.find(params[:code][:template]).code if params[:code].include?(:template)
      @code.contract = Contract.find(params[:code][:contract]) if params[:code].include?(:contract) && !params[:code][:contract].empty?
    end

    run_directives(code)
    scrape_events(code)
  end

  def run_directives(code)
    logger.info('Check for directives')
    old = Party.delete_all(code: code)
    content = code.code
    lines = content.split(/\r\n/)
    lines.grep(/\#NSCRYPT_DIRECTIVE\s+([a-zA-Z0-9_]+)\s+([a-zA-Z0-9_]+)/){
      if $1 == 'set_version'
        logger.info("Specified NScrypture version: #{$2}")
      elsif $1 == 'set_party_role'
        logger.info("Setting party role: #{$2}")
        party = Party.new
        party.role = $2
        party.code = code
        party.save
      else
        logger.info "WARNING: invalid directive action: #{$1}"
      end
    }
  end
  
  def scrape_events(code)
    logger.info('Scrape events.')
    old = ScEvent.delete_all(code: code)
    content = code.code
    lines = content.split(/\r\n/)
    lines.grep(/^\s*def\s+(sc_event_[a-zA-Z0-9_]+)/){
      sc_event = ScEvent.new
      sc_event.callback = $1
      sc_event.code = code
      sc_event.save
      logger.info($1)
      if $1 == 'sc_event_portal'
        code.sc_event_id = sc_event.id
        code.save
        if code.id == code.contract.signed_code_id
          code.contract.sc_event_id = sc_event.id
          code.contract.save
        end
      end
    }
  end    

end
