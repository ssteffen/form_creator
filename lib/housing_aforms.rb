unless Aform.where(:stub => "contact_housing").exists? 
  Aform.create!(:title => "Contact Housing", :stub => "contact_housing")
end
unless Aform.where(:stub => "apartment_application").exists? 
  Aform.create!(:title => "Apartments Application", :stub => "apartment_application")
end
unless Aform.where(:stub => "cancel_form").exists? 
  Aform.create!(:title => "Cancel Contract", :stub => "cancel_form")
end
unless Aform.where(:stub => "dining_application").exists? 
  Aform.create!(:title => "Dining Application", :stub => "dining_application")
end