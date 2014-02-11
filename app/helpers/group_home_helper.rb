module GroupHomeHelper
  
  def cache_key_for_groups(page: 1)
    agg_data = Group.aggregates(:updated_at)
    
    #puts agg_data
    
    count = agg_data['count']
    max_updated_at = agg_data['max'].try(:utc).try(:to_s, :number)
    "groups/all-page#{page}-#{count}-#{max_updated_at}"
  end
  
  def cache_key_for_group_category(category:, page: 1, deep: false)
    if deep == true
      agg_data = category.items(deep: true).stats
    else
      agg_data = category.items.stats
    end
    "groups/#{category.group.id}/cat/#{category.id}/page/#{page}-#{agg_data[:count]}-#{agg_data[:newest].try(:utc).try(:to_s, :number)}"
  end
end
