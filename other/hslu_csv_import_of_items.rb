# This is to be run from the Rails console using require:
# ./script/console
# require 'doc/csv_import_of_items'


require 'faster_csv'

import_file = "/tmp/items.csv"

@failures = 0
@successes = 0

def create_item(model_name, inventory_code, serial_number, manufacturer, category, accessory_string, note, price, purchase_date)
  
  m = Model.find_by_name(model_name)
  if m.nil?
    m = create_model(model_name, category, manufacturer, accessory_string)    
  end
  
  ip = InventoryPool.find_or_create_by_name("HSLU")
  
  i = Item.new
  i.model = m
  i.inventory_code = inventory_code
  i.serial_number = serial_number
  i.note = note
  i.owner = ip
  i.is_borrowable = true
  i.is_inventory_relevant = true
  i.inventory_pool = ip
  i.price = price
  i.invoice_date = purchase_date
  
  if i.save
    puts "Item imported correctly:"
    @successes += 1
    puts i.inspect
  else
    @failures += 1
    puts "Could not import item #{inventory_code}"
  end
  
  puts "-----------------------------------------"
  puts "DONE"
  puts "#{@successes} successes, #{@failures} failures"
  puts "-----------------------------------------"
  
end

def create_model(name, category, manufacturer, accessory_string)
  if category.blank?
    c = Category.find_or_create_by_name("Keine Kategorie")
  else  
    c = Category.find_or_create_by_name(category)
  end
  
  m = Model.create(:name => name, :manufacturer => manufacturer)
  m.categories << c
  
  unless accessory_string.blank?  
    accessory_string.split("-").each do |string|
      unless string.blank?
        acc = Accessory.create(:name => string.strip)
        m.accessories << acc
      end
    end
  end
  
  m.save

  return m
end

items_to_import = FasterCSV.open(import_file, :headers => true)

# CSV fields:
# 0: Bezeichnung
# 1: Inventarnummer
# 2: Seriennummer
# 3: Hersteller
# 4: Typ (= Kategorie)
# 5: Zubehör (comma-separated field)
# 6: Defekt: (-> Notiz)

items_to_import.each do |item|
  model_name = "#{item["Gerätebezeichnung"]} #{item["Typenbezeichnung"]}"
  note = "#{item["Referenzdatei Inventar"]} #{item["Fehler Reparatur"]}"
  price = item["Preis_Neu"].to_f
  # The purchase dates in the source file are only years, but Date.parse can't handle that,
  # so we add -01-01 to force to January 1.
  purchase_date = Date.parse("#{'Kaufdatum'}-01-01") unless item["Kaufdatum"].blank?

  
  create_item(model_name, 
              item["Inventarnummer_ID"],
              item["Seriennummer"],
              item["Marke"],
              item["Gerätekategorie"],
              item["Zubehör"],
              note,
              price,
              purchase_date)
end



