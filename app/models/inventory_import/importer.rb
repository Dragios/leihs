class InventoryImport::Importer
  
  def start(max = 999999)
    connect_dev
    #connect_prod
    inventar = InventoryImport::ItHelp.find(:all, :conditions => "rental like 'yes'",	:order => 'Inv_Serienr')
    count = 0
    
    import_inventory_pools

    inventar.each do |item|
      attributes = {
        :name => item.Art_Bezeichnung,
        :manufacturer => item.Art_Hersteller
      }
      model = Model.find_or_create_by_name attributes
      category = Category.find_or_create_by_name :name => item.Art_Gruppe_2
      category.model_links << ModelLink.create(:model => model, :quantity => 1) unless category.model_links.detect{| link |  link.model_id == model.id }
      category.save
      
      item_attributes = {
        :inventory_code => (item.Stao_Abteilung + item.Inv_Serienr.to_s),
        :serial_number => item.Art_Serienr,
        :model => model,
#old#        :inventory_pool => InventoryPool.find_or_create_by_name(item.Stao_Abteilung)
        :location => get_location(item.Stao_Abteilung, item.Stao_Raum)
      }
      item = Item.find_or_create_by_inventory_code item_attributes
      count += 1
      break if count == max
    end
    messages
  end
  
  def get_location(inventory_pool_name, location_name)
    inventory_pool = InventoryPool.find_or_create_by_name(inventory_pool_name)
    location = Location.find(:first, :conditions => {:name => location_name, :inventory_pool_id => inventory_pool.id})
    location = Location.create(:name => location_name, :inventory_pool => inventory_pool) unless location
    return location
  end
  
  def import_inventory_pools
    parks = InventoryImport::Geraetepark.find(:all)
    parks.each do |park|
      inv_park = InventoryPool.find_or_create_by_name({
        :name => park.name,
        :logo_url => park.logo_url,
        :description => park.beschreibung,
        :contract_description => park.vertrag_bezeichnung,
        :contract_url => park.vertrag_url        
      })
    end
  end
  
  def messages
    ["Erfolgreich abgeschlossen"] 
  end
  
  def connect_dev
    InventoryImport::Geraetepark.establish_connection(leihs_dev)
    InventoryImport::ItHelp.establish_connection(it_help_dev)
  end
  
  def it_help_dev
    {		:adapter => 'mysql',
    		:host => '127.0.0.1',
    		:database => 'ithelp_development',
    		:encoding => 'latin1',
    		:username => 'root',
    		:password => '' }
  end
  
  def leihs_dev
    {		:adapter => 'mysql',
    		:host => '127.0.0.1',
    		:database => 'rails_leihs_dev',
    		:encoding => 'utf8',
    		:username => 'root',
    		:password => '' }
  end
  
  def connect_prod
    InventoryImport::ItHelp.establish_connection(
    		:adapter => 'mysql',
    		:host => '195.176.254.22',
    		:database => 'help',
    		:encoding => 'utf8',
    		:username => 'magnus',
    		:password => '2read.0nly!' )

   InventoryImport::Geraetepark.establish_connection(
    		:adapter => 'mysql',
    		:host => '195.176.254.49',
    		:database => 'rails_leihs',
    		:encoding => 'utf8',
    		:username => 'leihsread',
    		:password => '2read.0nly!' )
  end

end
