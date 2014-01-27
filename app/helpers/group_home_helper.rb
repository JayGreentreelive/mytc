module GroupHomeHelper
  
  def cache_key_for_groups(page: 1)
    agg_data = Group.aggregates(:updated_at)
    
    #puts agg_data
    
    count = agg_data['count']
    max_updated_at = agg_data['max'].try(:utc).try(:to_s, :number)
    "groups/all-page#{page}-#{count}-#{max_updated_at}"
  end
  
end
