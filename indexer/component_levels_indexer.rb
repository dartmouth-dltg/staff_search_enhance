class StaffSearchIndexer < CommonIndexer
  include JSONModel
  #add_attribute_to_resolve('resource')
  add_indexer_initialize_hook do |indexer|
    indexer.add_document_prepare_hook {|doc, record|
      if record['record']['jsonmodel_type'] == 'archival_object'
        
        ao = record['record']

        resource_json = JSONModel::HTTP.get_json(ao['resource']['ref'])
  
        restrictions(doc, resource_json)
        
        if ao['restrictions_apply'] === true
          restrictions(doc, ao)
        end
        
        context = {}
        context["#{context_level(ao)}"] = ao['title']
        
        if ao['instances'] && ao['instances'].length > 0
          location = location_finder(ao['instances'])
        end
        
        parent_uri = ao['parent'] ? ao['parent']['ref'] : '' 
                
        until parent_uri.nil? || parent_uri.empty?
          parent_json = JSONModel::HTTP.get_json(parent_uri)
          
          if parent_json['restrictions_apply'] === true
            restrictions(doc, parent_json)
          end
          
          if parent_json['level']
            context["#{context_level(parent_json)}"] = parent_json['title']
          end
          
          unless location
            if parent_json['instances'] && parent_json['instances'].length > 0
              location = location_finder(parent_json['instances'])
            end
          end
          
          parent_uri = parent_json['parent'] ? parent_json['parent']['ref'] : ''
        end
        # add the resource
        context["resource"] = resource_json['title']
        doc['resource_title_u_sstr'] = resource_json['title']

        doc['location_u_sstr'] = location
        doc['context_u_sstr'] = ASUtils.to_json(Hash[context.to_a.reverse])
      
        call_number = (0..3).map{|i| resource_json["id_#{i}"]}.compact.join(".")
        
        doc['resource_identifier_u_sstr'] = call_number
      
        doc['resource_identifier_u_sort'] = (0..3).map{|i| (resource_json["id_#{i}"] || "").to_s.rjust(25, '#')}.join
        doc['resource_identifier_w_title_u_sstr'] = call_number + ": " + resource_json['title']
      end
    }
    
  indexer.add_document_prepare_hook {|doc, record|
      if record['record']['jsonmodel_type'] == 'resource'
        
        res = record['record']
        
        restrictions(doc, res)
                
        call_number = (0..3).map{|i| res["id_#{i}"]}.compact.join(".")
        doc['resource_identifier_u_sstr'] = call_number
        doc['resource_identifier_u_sort'] = (0..3).map{|i| (res["id_#{i}"] || "").to_s.rjust(25, '#')}.join
        doc['resource_identifier_w_title_u_sstr'] = call_number + ": " + res['title']
        
        if res['instances'] && res['instances'].length > 0
          location = location_finder(res['instances'])
        end
        doc['location_u_sstr'] = location

      end
    }
  indexer.add_document_prepare_hook {|doc, record|
    if record['record']['jsonmodel_type'] == 'accession'
      acc = record['record']
      restrictions(doc, acc)
      
      accession_number = (0..3).map{|i| acc["id_#{i}"]}.compact.join("-")
      unless acc['display_string'] == accession_number
          doc['title'] += "; #{accession_number}"
      end
      
      if acc['instances'] && acc['instances'].length > 0
        location = location_finder(acc['instances'])
      end
      doc['location_u_sstr'] = location

    end
    } 
  end
  
  def self.location_finder(instance_json)
    location = instance_json.
              collect{|instance| instance["container"]}.compact.
              collect{|container| container["container_locations"]}.flatten.
              collect{|container_location| container_location["_resolved"]}.compact.
              collect{|locations| locations['title']}.uniq.first
    containers = instance_json.
              collect{|instance| instance["container"]}.compact.
              collect{|container| (1..3).map{|i|
                    unless container['type_'+i.to_s].nil?
                      Hash[container['type_'+i.to_s] => container['indicator_'+i.to_s]]
                    end
              }.compact}.compact
    
    location_and_container = ASUtils.to_json(Hash[:location => location, :containers => containers])

    location_and_container
  end
  
  def self.restrictions(doc, json)
    if json['restrictions'] || json['restrictions_apply']
      doc['total_restrictions_u_sbool'] = true
      doc['restrictions_level_u_sstr'] = json['level'] ? json['level'] : json['primary_type']
    else
      doc['total_restrictions_u_sbool'] = false
      doc['restrictions_level_u_sstr'] = ''
    end
  end
  
  def self.context_level(json)
    if json['level'] == "otherlevel"
      level = json['other_level']
    else
      level = json['level']
    end
    
    level
  end
  
end
  