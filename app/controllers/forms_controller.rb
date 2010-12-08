class FormsController < ApplicationController
  # GET /forms
  # GET /forms.xml
  def index
    @forms = Form.all
    @aforms = Aform.all
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @forms }
    end
  end

  # GET /forms/1
  # GET /forms/1.xml
  def show
    @form = Form.find(params[:id])
    
    #respond_to do |format|
    #  format.html # show.html.erb
    #  format.xml  { render :xml => @form }
    #end
    redirect_to :action => "display_form"
  end

  # GET /forms/new
  # GET /forms/new.xml
  def new
    @form = Form.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @form }
    end
  end

  # GET /forms/1/edit
  def edit
    @form = Form.find(params[:id])
  end

  # POST /forms
  # POST /forms.xml
  def create
    @form = Form.new(params[:form])
    @form.fields = ""
    respond_to do |format|
      if @form.save
        format.html { redirect_to(@form, :notice => 'Form was successfully created.') }
        format.xml  { render :xml => @form, :status => :created, :location => @form }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @form.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /forms/1
  # PUT /forms/1.xml
  def update
    @form = Form.find(params[:id])

    respond_to do |format|
      if @form.update_attributes(params[:form])
        format.html { redirect_to(@form, :notice => 'Form was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @form.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /forms/1
  # DELETE /forms/1.xml
  def destroy
    @form = Form.find(params[:id])
    @form.destroy

    respond_to do |format|
      format.html { redirect_to(forms_url) }
      format.xml  { head :ok }
    end
  end
  
  def edit_fields
    @form = Form.find(params[:id])
    session[:form_id] = @form.id
    unless @form.fields.blank?
      @fields = YAML.load(@form.fields)
    end
  end
  
  def add_field
    if request.get?
      @info = Hash.new
      @field_hash = Hash.new
      session[:count] = 1
    else
      @fields = []
      @field_hash = Hash.new
      session[:field_hash] = @field_hash
      form = Form.find(session[:form_id])
      @info = params[:info]
      if form.fields.blank?
        logger.info 'FIELDS TO BE FILLED'
        form.fields = {}
      else
        @fields = YAML::load(form.fields)
        logger.info "Loading YAML {line 92}"
      end     
      @fields << @info
      form.fields = @fields.to_yaml
      form.save
      logger.info "Returned: #{@info}"
      redirect_to :action => 'edit_fields'
    end
  end
  
  
  def edit_field
    if request.get?
      @field_hash = Hash.new
      @fields = []
      @field_name = CGI.unescape(params[:field_id])  
      session[:field_name] = @field_name
      form = Form.find(params[:id])
      unless form.fields == ""
        @fields = YAML::load(form.fields)
        for field in @fields
          if field[:fields_name] == @field_name
            @field_hash = field
            session[:field_hash] = field
            if field[:fields_type] == "Select Box"
              @field = field.sort_by {|x| x[0][19 .. -1].to_i}
            elsif field[:fields_type] == "Check Box"
              @field = field.sort_by {|x| x[0][17 .. -1].to_i}
            elsif field[:fields_type] == "Radio Button"
              @field = field.sort_by {|x| x[0][21 .. -1].to_i}
            else
              @field = field.sort
            end
            #logger.info "FIELD O: #{@field[0][0]}"
            logger.info "Field: #{@field.to_s}"
          end
        end
      end
      @f = @field_hash[:fields_type].downcase
      #logger.info "FIELD HASH: #{@field_hash.to_s}"
    else
      @fields = []
      @field_hash = Hash.new
      form = Form.find(params[:id])
      @field_name = session[:field_name]
      session[:field_name] = nil
      unless form.fields == ""
        @fields = YAML::load(form.fields)
        logger.info "YAML: #{@fields.to_s}"
        for field in @fields
          if field[:fields_name] == @field_name
            @field_hash = field
            logger.info "Field: #{@field_hash.to_s}"
            @edit = params[:info]
            ind = @fields.index(field)
            logger.info "FIELD: #{field.to_s}"
            @fields[ind] = @edit
            form.fields = @fields.to_yaml
            logger.info "YAML: #{@fields.to_yaml}"
            form.save
            redirect_to :action => 'edit_fields' and return
          end
        end
        #if @field_hash.empty?
        #  logger.info "Field not found"
        #  redirect_to :action => 'add_fields'
        #end
      end
    end
  end
  
  #Deletes individual fields
  def delete_field
    name = CGI.unescape(params[:id])
    form = Form.find(session[:form_id])
    fields = YAML::load(form.fields)
    for hash in fields do
      if hash[:fields_name] == name
        fields.delete(hash)
        session[:field_hash] = nil
      end
    end
    if fields.empty?
      form.fields = ""
    else
      form.fields = fields.to_yaml
    end
    form.save
    flash[:notice] = "Field Deleted."
    redirect_to :action => 'edit_fields'
  end
  
  def delete_all_fields
    form = Form.find(session[:form_id])
    form.fields = ""
    form.save!
    flash[:notice] = "All Fields Deleted."
    redirect_to :action => 'edit_fields'
  end
  
  def change_type(type = nil)
    #@radio_buttons = session[:count]
    session[:count] = 1
    @field_hash = Hash.new
    @field_hash = session[:field_hash]
    path = "forms/field_partials/"
    @type = params[:type]
    if(type)
      @type = type
    end
    @type_path = case @type
      when "Text Field" then "#{path}text_field_options.html.erb"
      when "Text Area" then "#{path}text_area_options.html.erb"
      when "Check Box" then "#{path}check_box_options.html.erb"
      when "Radio Button" then "#{path}radio_button_options.html.erb"
      when "Select Box" then "#{path}select_box_options.html.erb"
      when "Numbered Select Box" then "#{path}n_select_box_options.html.erb"
      when "Date Select" then "#{path}date_select_options.html.erb"
      when "Time Select" then "#{path}time_select_options.html.erb"
      when "DateTime Select" then "#{path}datetime_select_options.html.erb"
      when "State Select" then "#{path}state_select_options.html.erb"
      when "Country Select" then "#{path}country_select_options.html.erb"
      when "Paragraph" then "#{path}paragraph_options.html.erb"
      when "Accept Terms" then "#{path}accept_terms.html.erb"
      else "#{path}blank.html.erb"
    end
  end
  
  ################################################
  #The following methods go together for
  # radio buttons, select boxes, and check boxes
  # to dynamically create fields, there
  # is a lot of duplicated code, but the seperate
  # methods were necessary for the partials.
  ###############################################
  def add_select_option()
    session[:count] += 1
  end
  
  def remove_select_option
    if params[:id]
      @count = params[:id]
    end
  end
  
  def add_checkbox_options()
    session[:count] += 1
  end
  
  def remove_checkbox_option
    if params[:id]
      @count = params[:id]
    end
  end
  
  def add_radio_options()
    session[:count] += 1
  end
  
  def remove_radio_option
    if params[:id]
      @count = params[:id]
    end
  end
    
  ##########################
  #END Dynamic field methods.
  
  # Submissions Control
  def submissions
    @form = Form.find(params[:id])
    @sub_array = []
    @hash = Hash.new
    @subs = FormSubmission.where(:form_id => @form.id)
    @results = @subs.paginate :page => params[:page], :order => "created_at DESC"
  end

  def alt_submissions
    @form = Aform.find(params[:id])
    @sub_array = []
    @subs = FormSubmission.where(:a_form_id => @form.id)
    @results = @subs.paginate :page => params[:page], :order => "created_at DESC"
  end
  
  def delete_result
    form_result = FormSubmission.find(params[:id])
    form_id = form_result.form_id
    if form_result.delete
      flash[:notice] = "Result successfully deleted."
    else
      flash[:notice] = "Error occured, result not deleted."
    end
    redirect_to :action => 'view_submissions', :id => form_id
  end
  
  def view_result
    @form_result = FormSubmission.find(params[:id])
    @form = Form.find(@form_result.form_id)
    @results_hash = YAML.load(@form_result.response)
    @fields = YAML.load(@form.fields)   
    @results = []
    @name = ""
    for result in @results_hash
      if result[0] =~ /(name)/
        @name = result[1]
        break
      end 
    end
    @checkbox_hash = Hash.new
    for field in @fields
      @results_hash.each_pair{|k,v| logger.info "KEY: #{k}, VALUE: #{v}"}
      for result in @results_hash
        #logger.info "RESULT [0]: #{result[0].gsub('_', ' ')} ==== Fields_Name: #{field[:fields_name].downcase}"
        #logger.info "2nd try: #{result[0].gsub('_', ' ').gsub(field[:fields_name].downcase, '').downcase} ========= #{result[1].downcase}"
        if result[1].is_a?(Hash) && (result[1].has_key?("day") || result[1].has_key?("hour")) && (result[0].gsub('_', ' ') == (field[:fields_name]).downcase)
          @second_hash = Hash.new
          @second_hash = result
          if field[:fields_type] == "Date Select"
            @results << [result[0], "#{result[1][:month]}/#{result[1][:day]}/#{result[1][:year]}"]
          elsif field[:fields_type] == "DateTime Select"
            @results << [result[0], "#{result[1][:hour]}:#{result[1][:minute]} on #{result[1][:month]}/#{result[1][:day]}/#{result[1][:year]}"]
          elsif field[:fields_type] == "Time Select"
            @results << [result[0], "#{result[1][:hour]}:#{result[1][:minute]}"]
          end
        else
          unless result[1].is_a?(Hash)
            #logger.info "Result[1] is not a hash"
            if (result[0].gsub('_', ' ') == (field[:fields_name]).downcase) || 
              (result[0].gsub('_', ' ').gsub(field[:fields_name].downcase, '').downcase == ' ' + result[1].downcase)
              if(field[:fields_type] == "Check Box")
                @results << [field[:fields_name], "Check Box"]
                if @checkbox_hash[field[:fields_name].to_sym]
                  @checkbox_hash[field[:fields_name].to_sym] << [result[1]]
                else
                  @checkbox_hash[field[:fields_name].to_sym] = [result[1]]
                end
              else
                @results << result
              end
            end
          end
        end
      end
    end
    #logger.info "RESULTS #{@results.to_s}"
  end
  
  def view_alt_result
    @form_result = FormSubmission.find(params[:id])
    @form = Aform.find(@form_result.a_form_id)
    @order = YAML.load(@form.field_order)
    @results = []
    found_names = false
    logger.info "Form: #{@form.to_s}"
    @results_hash = YAML.load(@form_result.response)
    #Re-order
    for field in @order
      for result in @results_hash
        if result[0] == field
          @results << result
        end
      end
    end
    for result in @results_hash
      logger.info "RESULT: #{result[0]} == first_name"
      if result[0] == "first_name"
        found_names = true
        logger.info "#{result[0]}"
        @name = result[1]
        for r in @results_hash
          logger.info "LAST NAME: #{r[0]} == last_name"
          if r[0] == "last_name"
            @name += " #{r[1]}"
            logger.info "#{@name}"
            break
          end
        end
        break
      end
    end
    unless found_names
      for result in @results_hash do
        logger.info "NAME: #{@name}"
        if result[0] =~ /(name)/
          @name = result[1]
          break
        end
      end 
    end
  end
  
  
  ####################################
  # Begin Display Methods
  # START FRONT END METHODS
  # VALIDATION CHECKING METHODS
  def check_names(object, field1 = nil, field2 = nil, field3 = nil)
     if field1 && field2.nil? && field3.nil?
       if (object[field1].blank?)
         flash[:notice] << ["#{field1} is required.<br />"]
       end
     elsif field1 && field2 && field3.nil?
       if (object[field1].blank? || object[field2].blank?)
         flash[:notice] << ["#{field1} and #{field2} are required.<br />"]
       end
     elsif field1 && field2 && field3
       if (object[field1].blank? || object[field2].blank? || object[field2].blank?)
         flash[:notice] << ["#{field1}, #{field2} and #{field3} are required.<br />"]
       end 
     end
   end


   #checks if empty then splits a single name input into two or three parts.
   def check_and_split_name(object, name, required)
     if object[name].blank?
       if required == true
         flash[:notice] << ["#{name} is required.<br />"]
       end
     else
       split_name = object[name].split
       if !(split_name.length == 2 || split_name.length == 3 || split_name.length == 4)
         flash[:notice] << ["A valid #{name} is required. Must at least contain first, last.<br />"]
       end
     end
   end    


   #Checks for a valid set of addresses
   def check_address(object, street, city, zip)
     if(object[street].blank? || object[city].blank? || object[zip].blank?)
       flash[:notice] << ["#{street}, #{city}, and #{zip} are required.<br />"]
     elsif !(object[zip].size == 5 || object[zip].size == 10)
       flash[:notice] << ["Valid #{zip} is required.<br />"]
     end
   end

   def check_zip(object, zip, required)
     if object[zip].blank?
       if required == true
         flash[:notice] << ["#{zip} is required.<br />"]
       end
     elsif !(object[zip].size == 5 || object[zip].size == 10)
       flash[:notice] << ["Valid #{zip} is required.<br />"]
     end
   end

   def check_date(object, date, name)
     if (object[date] !~ /\d{2}\/\d{2}\/\d{2}/)
       flash[:notice] << ['Valid ' + name + ' in the form of (mm/dd/yy) is required<br />']
     end
   end

   def check_email(object, att, required)
     if(object[att].blank? || !(object[att] =~ /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i))
       flash[:notice] << ["A valid #{att} is required.<br />"]
     end
   end

   def check_email_confirm(object, att, att2, required)
     if(object[att].blank? || !(object[att] =~ /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i))
       flash[:notice] << ['Please enter a valid email address and confirm it.<br />']
     end
   end

   def check_phone(object, att, required)
     if(object[att].blank?)
       if required == true
         flash[:notice] << ["Please enter a valid #{att}.<br />"]
       end
     else
       phone_dig = object[att].gsub(/[^0-9]/,'')
       if(phone_dig.size != 10)
         flash[:notice] << ["Please enter a valid #{att}.<br />"]
       end
     end
   end

   def check_dawgtag(object, dawgtag, required)
     if(object[dawgtag].blank?)
       if required == true
         flash[:notice] << ["#{dawgtag} is required.<br />"]
       end
     elsif object[dawgtag].size != 9 && object[dawgtag] =~ /\d{9}/
       flash[:notice] << ["A valid #{dawgtag} is required.<br />"]
     end
   end
   
   def check_date_text_format(object, textfield, required)
     if object[textfield].blank?
       if required == true
         flash[:notice] << ["#{textfield} is required.<br />"]
       end
     else 
       unless object[textfield] =~ /[0-9]{2}\/[0-9]{2}\/[0-9]{4}/
         flash[:notice] << ["#{textfield} is not in the correct format. Make sure it is mm/dd/yyyy. <br />"]
       end
     end
   end

   def check_agree(object, agree)
     if(object[agree] != '1')
       flash[:notice] << ['You must agree to the policy. <br />']
     end
   end

   def check_field(object, att, required)
     logger.info "In Check Field"
     if required == true
       if(object[att].blank?)
        flash[:notice] << ["#{att} field cannot be blank.<br />"]
       end
     end 
   end

   def check_plain(object, att, required)
     if object[att].blank?
       if required == true
         flash[:notice] << ["#{att} is required.<br />"]
       end
     elsif(object[att] =~ /[^a-zA-Z .,'":]/)
       flash[:notice] << ["#{att} must not contain numbers or special characters.<br />"]
     end 
   end
   # END VALIDATION CHECKING METHODS
   
  #BEGIN MAIN ACTIONS
  def list_forms
    @form_list = Form.all
    @alt_forms = Aform.all
  end
  
  def display_form
    @form = Form.find(params[:id])
    fields = YAML.load(@form.fields)
    @fields_array = []
    @fields_array = fields
    for a in @fields_array
      a.each_pair{|k,v| logger.info "#{k}: #{v}"}
      logger.info '---------------------------------'
    end
    if request.get?
      @sub = Hash.new 
    else
      @sub = params[:form]
      flash[:notice] = []
      
      # BEGIN FIELD LOOP
      for field in @fields_array do
        
        name = field[:fields_name].downcase.gsub(' ', '_')
        if @sub.has_key?(field[:fields_name].downcase.gsub(' ', '_'))
          
          # VALIDATION CHECKING
          if field[:fields_type] == "Text Field"
            # Email validation
            if field[:validation_type] == "Email"
              if field[:required_field] == "Yes"
                check_email(@sub, name.to_sym, true)
              else 
                check_email(@sub, name.to_sym, false)
              end   
            # Phone Validation  
            elsif field[:validation_type] == "Phone Number"
              if field[:required_field] == "Yes"
                check_phone(@sub, name.to_sym, true)
              else
                check_phone(@sub, name.to_sym, false)
              end 
            # Zip Validation 
            elsif field[:validation_type] == "Zip Code"
              if field[:required_field] == "Yes"
                check_zip(@sub, name.to_sym, true)
              else
                check_zip(@sub, name.to_sym, false)
              end
            # Dawgtag Validation
            elsif field[:validation_type] == "Dawgtag"
              if field[:required_field] == "Yes"
                check_dawgtag(@sub, name.to_sym, true)
              else
                check_dawgtag(@sub, name.to_sym, false)
              end
            # Plain Characters Validation
            elsif field[:validation_type] == "Plain"
              if field[:required_field] == "Yes"
                check_plain(@sub, name.to_sym, true)
              else
                check_plain(@sub, name.to_sym, false)
              end
            # Default Validation
            elsif field[:validation_type] == "Default"
              if field[:required_field]
                check_field(@sub, name.to_sym, true)
              else
                check_field(@sub, name.to_sym, false)
              end
            end
          else
            # Other Validation 
            if field[:required_field] == "Yes"
              check_field(@sub, name.to_sym, true)
            end
          end
          
        end
        #Check for term agreements
        if field[:fields_type] == "Accept Terms"
          logger.info "TERMS AND CONDITIONS: #{@sub[name.to_sym]}"
          if @sub[name.to_sym].nil? || @sub[name.to_sym] != "Accept"
            flash[:notice] << ['You must accept the terms and conditions of the form.<br />']
          end
        end
        #Check for Date Select
        if field[:fields_type] == "Date Select" || field[:fields_type] == "DateTime Select" || field[:fields_type] == "Time Select"
          @sub[name.to_sym] = Hash.new
          @sub[name.to_sym] = params[name.to_sym]
          #logger.info "Name: #{name.to_sym}"
          #logger.info "Params: #{params[name.to_sym].to_s}"
        end
      end 
      @sub.each_pair{|k,v| logger.info "#{k}: #{v}"}
      logger.info "---------------------------------"
      # END FIELD LOOP

      if flash[:notice].empty?
        yaml_string = @sub.to_yaml
        response = FormSubmission.new(:response => yaml_string, :form_id => @form.id)
        if response.save
          unless @form.email_notification_address.blank?
            FormMailer.new_forms_notification(@form, response.id).deliver
          end
          flash[:notice] << [@form.success_message + "<br />"]
        else
          flash[:notice] << [@form.failure_message + "<br />There was a problem saving your submission. Please try again later.<br />"]
        end
      else
        flash[:notice].insert(0, @form.failure_message + "<br />")
      end
    end
  end
  # End of Dynamic "display_form" method.
  
  
  # Older Forms that cannot be reasonably transferred to new system go here. 
  # They will use the same validation methods as above.
  # They will also need to have require_ssl options for each method at the top of this file
  # Each method requires an array named @order so that the fields will be sorted properly for the responses
  # Dining Employment Application
  def dining_application
    
    #@page = Page.new
    #@page.title = "Dining Employment Application"
    #@page.updated_at = Time.now
    @dining_application = Hash.new
    @availability_hours = ["Not Available", "8am", "9am", "10am", "11am", "12am", "1pm", "2pm", "3pm", "4pm", "5pm", "6pm", "7pm", "8pm"]
    @order = ["first_name", "last_name", "dawgtag", "month", "day", "year", "campus_address", "email", "confirm_email", "local_phone", "home_phone", "street",
              "city", "state", "zip", "country", "employed_before", "position", "employment_start", "employment_end", "employment_building", "supervisor", 
              "current_status", "status_explanation", "mon_avail", "tue_avail", "wed_avail", "thu_avail", "fri_avail", "first_position", "first_work_type", 
              "first_employer", "first_address", "first_phone", "first_supervisor", "first_employ_start", "first_employ_end", "first_reason", "second_position", 
              "second_work_type", "second_employer", "second_address", "second_phone", "second_supervisor", "second_employ_start", "second_employ_end", "second_reason", 
              "third_position", "third_work_type", "third_employer", "third_address", "third_phone", "third_supervisor", "third_employ_start", "third_employ_end", 
              "third_reason", "typing", "wpm", "calculator", "cash", "reception", "excel", "photoshop", "word", "publisher", "illustrator", "pagemaker", "quark", 
              "indesign", "powerpoint", "other", "calligraphy", "advertising", "graphics", "marketing", "trueblood_dining", "eastside_express", "university_hall_dining",
              "lentz_dining", "add_know", "comments"]
    
    unless request.get?
      flash[:notice] = []
      @dining_application = params[:dining_application]
      @dining_application.each_pair{|k, v| logger.info "#{k}: #{v}"}
      check_field(@dining_application, :first_name, true)
      check_field(@dining_application, :last_name, true)
      check_dawgtag(@dining_application, :dawgtag, true)
      check_email(@dining_application, :email, true)
      check_email(@dining_application, :confirm_email, true)
      unless @dining_application[:email] == @dining_application[:confirm_email]
        flash[:notice] << ['Your emails do not match. Please ensure you correctly confirm your email address.<br />']
      end
      check_phone(@dining_application, :local_phone, false)
      check_phone(@dining_application, :home_phone, false)
      check_zip(@dining_application, :zip, false)
      check_date_text_format(@dining_application, :employment_start, false)
      check_date_text_format(@dining_application, :employment_end, false)
      check_phone(@dining_application, :first_phone, false)
      check_date_text_format(@dining_application, :first_employ_start, false)
      check_date_text_format(@dining_application, :first_employ_end, false)
      check_phone(@dining_application, :second_phone, false)
      check_date_text_format(@dining_application, :second_employ_start, false)
      check_date_text_format(@dining_application, :second_employ_end, false)
      check_phone(@dining_application, :third_phone, false)
      check_date_text_format(@dining_application, :third_employ_start, false)
      check_date_text_format(@dining_application, :third_employ_end, false)
      check_agree(@dining_application, :agree)
      if flash[:notice].empty?
        yaml_response = @dining_application.to_yaml
        form = Aform.find(:first, :conditions => {:stub => "dining_application"})
        response = FormSubmission.new(:a_form_id => form.id, :response => yaml_response)
        if response.save
          flash[:notice] = "Thank you for submitting an application for employment at University Housing. 
                            You will be contacted by University Housing staff when your application has been reviewed."
          form = Aform.find(:first, :conditions => {:title => "Dining Application"})
          logger.info "Checking order"
          # Required for sorting
          if form.field_order.nil? || @order != YAML.load(form.field_order)
            logger.info "overwriting"
            form.field_order = @order.to_yaml
            form.save
          end
          FormMailer.new_forms_alt_notification(form, response.id, "fooddine@siu.edu").deliver
        else
          flash[:notice] = "There was an error submitting your application. Please try again later."
        end
      end
    end
  end
  #End of Dining Employment Application
  
  # Housing Apartments Application
  def apartment_application
     #@page = Page.new
     #@page.title = "Application for University Housing Apartments"
     #@page.updated_at = Time.now
     @apartment_application = Hash.new
     @order = ["semester", "first_name", "middle_initial", "last_name", "gender", "birthdate", "email", "dawgtag", "marital_status", "wedding_date",
               "spouse_last_name", "spouse_first_name", "spouse_init", "spouse_id", "spouse_status", "spouse_gender",
               "contact_phone", "home_phone", "street", "city", "state", "country", "zip", "no_children",
               "child_name_1", "child_gender_1", "child_bdate_1", "child_name_2", "child_gender_2", "child_bdate_2",
               "child_name_3", "child_gender_3", "child_bdate_3", "child_name_4", "child_gender_4", "child_bdate_4", 
               "student_status", "law", "med", "other", "department", "move_in_date", "preference_1", "preference_2", "previous_housing", 
               "disability", "disability_info", "crime", "offense", "comments" ]
     
     unless request.get?
       flash[:notice] = []
       @apartment_application = params[:apartment_application]
       check_field(@apartment_application, :last_name, true)
       check_field(@apartment_application, :first_name, true)
       check_field(@apartment_application, :street, true)
       check_field(@apartment_application, :city, true)
       if(@apartment_application[:country] == "United States")
         check_zip(@apartment_application, :zip, true)
         check_phone(@apartment_application, :home_phone, true)
         check_phone(@apartment_application, :contact_phone, true)
       end
       check_email(@apartment_application, :email, true)
       check_dawgtag(@apartment_application, :dawgtag, false)
       check_date_text_format(@apartment_application, :birthdate, true)
       unless @apartment_application[:marital_status] == "Single"
         check_field(@apartment_application, :spouse_last_name, true)
         check_field(@apartment_application, :spouse_first_name, true)
         check_field(@apartment_application, :spouse_id, true)
         @spouse_birthday = params[:spouse_birthday]
         @apartment_application[:spouse_birthday] = "#{@spouse_birthday[:month]}/#{@spouse_birthday[:day]}/#{@spouse_birthday[:year]}"
       end
       if @apartment_application[:marital_status] == "Engaged"
         @wedding_date = params[:wedding_date]
         @apartment_application[:wedding_date] = "#{@wedding_date[:month]}/#{@wedding_date[:day]}/#{@wedding_date[:year]}"
       end
       @apartment_application[:move_in_date] = "#{@apartment_application[:month]}/#{@apartment_application[:day]}/#{@apartment_application[:year]}"
       @apartment_application[:month] = nil
       @apartment_application[:day] = nil
       @apartment_application[:year] = nil
       unless @apartment_application[:no_children] == "0"
         for i in 1..@apartment_application[:no_children].to_i do
           check_field(@apartment_application, "child_name_#{i}".to_sym, true)
           check_date_text_format(@apartment_application, "child_bdate_#{i}".to_sym, true)
         end
       end
       if @apartment_application[:disability] == "Yes"
         if @apartment_application[:disability_info].blank?
           flash[:notice] << ["Please inform us of the condition of your disability. <br />"]
         end
       end
       if @apartment_application[:crime] == "Yes"
         if @apartment_application[:offense].blank?
           flash[:notice] << ['Please explain the crime. <br />']
         end
       end
       check_agree(@apartment_application, :agreement)
       if flash[:notice].empty?
         yaml_response = @apartment_application.to_yaml
         form = Aform.find(:first, :conditions => {:stub => "apartment_application"})
         response = FormSubmission.new(:a_form_id => (Aform.where(:stub => "apartment_application")).id, :response => yaml_response)
         if response.save
           flash[:notice] = "Thank you for submitting your application to University Housing Apartments.<br />  
                             Please be sure to check the information at the end of the page for information on when your application will be processed."
           form = Aform.find(:first, :conditions => {:title => "Apartment Application"})
           # Required for sorting
           if form.field_order.nil? || @order != YAML.load(form.field_order)
             logger.info "overwriting"
             form.field_order = @order.to_yaml
             form.save
           end
           FormMailer.new_forms_alt_notification(form, response.id, "housing@siu.edu").deliver
         else
           flash[:notice] = "There was an error submitting your application. Please try again later."
         end
       end
     end
   end
   
   #Contract Cancellation Form
   def cancel_form  
     #Set up Time objects
     #@page = Page.new
     #@page.updated_at = Time.now
     #@page.title = "Cancel Contract"
     @order = ["name", "cancel_for", "status", "type", "email", "dawgtag", "room", "reason", "comments"]
     current_date = Time.now
     cancel_for = 0
     next_year = current_date.next_year
     begin_fall = Time.parse('11/10/' + (current_date.year - 1).to_s).at_midnight
     end_fall = Time.parse('8/20/' + current_date.year.to_s).tomorrow - 1
     begin_spring = Time.parse('10/1/' + current_date.year.to_s).at_midnight
     end_spring = Time.parse('1/12/' + (current_date.year + 1).to_s).tomorrow - 1

     #set up time objects for @cancel_form[:cancel_for] radio buttons
     start_fall = Time.parse('8/20/' + current_date.year.to_s).at_midnight
     start_spring = Time.parse('11/9/' + current_date.year.to_s).at_midnight
     start_summer = Time.parse('5/8/' + current_date.year.to_s).at_midnight


     @fall = false
     @spring = false
     @summer = false

     #Check availability of page
     ip = request.remote_ip  
     if (current_date >= begin_fall && current_date <= end_fall)
       cancel_for = 1
     elsif (current_date >= begin_spring && current_date <= end_spring)
       cancel_for = 1
     end
     #if (!(current_date <= end_fall && current_date >= begin_fall) || !(current_date <= end_spring && current_date >= begin_spring)) 
     #if (cancel_for == 0)
     #  if (ip != '131.230.19.56' )
     #    redirect_to "http://www.housing.siu.edu"
     #  end
     #end
     #Set up the dynamic cancellation semester
     logger.info "#{current_date >= start_spring}"
     if (current_date >= start_fall && current_date <= start_spring)
       @fall = true
     elsif (current_date >= start_spring && current_date <= Time.now.end_of_year && current_date.year + 1 <= start_summer.year + 1 )
       @spring = true
     else
       @summer = true
     end
     logger.info "TIME: Fall:#{@fall} Spring:#{@spring} Summer:#{@summer}"
     #predefine charge information
     #start of form info
     @page_title = "Housing Contract Cancellation Form - Students"
     if request.get?
       @cancel_form = Hash.new
     else
       @cancel_form = params[:cancel_form]
       flash[:notice] = []

       if (@cancel_form[:status] == '1')
         @cancel_form[:student] = 'New Student'
       else
         @cancel_form[:student] = 'Current Redawgtagent'
       end

       if (@cancel_form[:type] == '1')
         @cancel_form[:contract] = '1-Year Basic'
       else
         @cancel_form[:contract] = '2-Year Edge'
       end

       #FAILURE CASES****************
       if (@cancel_form[:name].blank?)
         flash[:notice] << ['Please enter your name. <br />']
       end
       if (@cancel_form[:cancel_for].nil?)
         flash[:notice] << ['Please select the semester you are canceling for. <br />']
       end
       if (@cancel_form[:email].blank? || !(@cancel_form[:email] =~ /(.+)@(.+)\.(.{3})/))
         flash[:notice] << ['A valid email address is required. <br />']
       end
       if (@cancel_form[:dawgtag].blank? || @cancel_form[:dawgtag].size != 9)
         flash[:notice] << ['A valid Dawgtag is required. <br />']
       end
       if (@cancel_form[:reason] == 'not attending SIUC' && @cancel_form[:comments].blank?)
         flash[:notice] << ['Please enter where you will be attending. <br />']
       end
       #if (@cancel_form[:reason] == 'Living off Campus' && @cancel_form[:comments].blank?)
       #  flash[:notice] << ['Please enter your new address. <br />']
       #end
       if (@cancel_form[:reason] == 'RA' && @cancel_form[:comments].blank?)
         flash[:notice] << ['Please enter where you will be an RA. <br />']
       end
       #if (@cancel_form[:reason] == 'other' && @cancel_form[:comments].blank?)
       #  flash[:notice] << ['Please enter your reason for cancelling. <br />']
       #end
       if (@cancel_form[:agreement] != '1')
         flash[:notice] << ['You must agree to the policy and fees. <br />']
       end
       #
       #SUCCESS CASE***********
       #
       if (flash[:notice].blank?)
            yaml_response = @cancel_form.to_yaml
            form = Aform.find(:first, :conditions => {:title => "Cancel Contract"})
            response = FormSubmission.new(:a_form_id => form.id, :response => yaml_response)
            if response.save
              flash[:notice] = "Cancel form submitted successfully. You will receive confirmation of your cancellation \"how\". If you do not receive a confirmation please contact the Contracts Office at 618.453.2301"
              # Required for sorting
              if form.field_order.nil? || @order != YAML.load(form.field_order)
                logger.info "overwriting"
                form.field_order = @order.to_yaml
                form.save
              end
             FormMailer.new_forms_alt_notification(form, response.id, "housing@siu.edu").deliver
            else
              flash[:notice] = "There was an error submitting your cancellation form. Please try again later."
            end
       end
     end
   end
   
   #Contact Housing Form
   def contact_housing
      #@page = Page.new
      #@page.updated_at = Time.now
      #@page.title = "Contact Housing"
      @order = ["name", "email", "enrollment", "enrollment_semester", "enrollment_year", "enrollment_class", "address_perm", "city_perm", 
                "state_perm", "zip_perm", "country_perm", "phone_perm", "address_sc", "city_sc", "state_sc", "zip_sc", "country_sc", "phone_sc",
                "pref", "comments"]
      if request.get?
        @contact_housing = Hash.new
      else
        @contact_housing = params[:contact_housing]
        @contact_housing[:enrollment_year] = params[:date][:enrollment_year]
        @contact_housing[:pdigit] = @contact_housing[:phone_perm].gsub(/[^0-9]/,'')
        @contact_housing[:sdigit] = @contact_housing[:phone_sc].gsub(/[^0-9]/,'')

        email = @contact_housing[:email]
        flash[:notice] = []
        if (@contact_housing[:country_sc] != "United States")
          @contact_housing[:state_sc] = ""
          @contact_housing[:zip_sc] = ""
        end
        if (@contact_housing[:country_perm] != "United States")
          @contact_housing[:state_perm] = ""
          @contact_housing[:zip_perm] = ""
        end
       case @contact_housing[:enrollment]
        when "1"
           @contact_housing[:enroll_message] = "Currently a student at SIUC"
        when "2"
           @contact_housing[:enroll_message] = "Planning on attending SIUC in the " + @contact_housing[:enrollment_semester] + " of " + @contact_housing[:enrollment_year]
        when "3"
           @contact_housing[:enroll_message] = "Currently not planning on attending SIUC or a parent of an SIUC student"
        end

        if @contact_housing[:name].blank? || @contact_housing[:email].blank? || @contact_housing[:address_perm].blank? || @contact_housing[:city_perm].blank?
          flash[:notice] << ["All fields marked with '*' must be filled <br />"]
        end
        if (@contact_housing[:pdigit].size != 0 && @contact_housing[:pdigit].size != 10) 
            flash[:notice] << ["Please enter a valid permanent phone number and area code. <br />"]
        end
        if (@contact_housing[:sdigit].size != 0 && @contact_housing[:sdigit].size != 10) 
            flash[:notice] << ["Please enter a valid school phone number and area code. <br />"]
        end
        check_zip @contact_housing, :zip_perm, true
        check_zip @contact_housing, :zip_sc, true
       
        if !(email =~ /(.+)@(.+)\.(.{3})/)
          flash[:notice] << ["Please enter a valid email address <br />"]
        end
        if (flash[:notice].blank?)
          yaml_response = @contact_housing.to_yaml
          form = Aform.find(:first, :conditions => {:title => "Contact Housing"})
          response = FormSubmission.new(:a_form_id => form.id, :response => yaml_response)
          if response.save
            flash[:notice] = "Contact information successfully sent."
            # Required for sorting
            if form.field_order.nil? || @order != YAML.load(form.field_order)
              logger.info "overwriting"
              form.field_order = @order.to_yaml
              form.save
            end
            FormMailer.new_forms_alt_notification(form, response.id, "housing@siu.edu").deliver
          else
            flash[:notice] = "There was an error submitting your contact form. Please try again later."
          end
        end    
      end  
    end
end
