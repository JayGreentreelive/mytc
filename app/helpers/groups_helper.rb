module GroupsHelper
  
  
  def entity_desc(ent)
    if ent.is_a? UmbcPerson
      ent.umbc_title || ent.umbc_username || ent.umbc_campus_id
    elsif ent.is_a? Person
      ent.display_email
    elsif ent.is_a? Group
      case ent.kind
      when :institutional
        'Institutional Group'
      when :studentorg
        'Student Org'
      when :interest
        'Interest Group'
      when :legacy
        'Legacy Group'
      else
        "Unknown Kind: #{ent.kind}"
      end
    else
      'Unknown'
    end
  end
  
  def entity_avatar(ent)
    
    if ent.is_a? Person
      ent_type = :person
      initials = ent.first_name[0].try(:upcase) + ent.last_name[0].try(:upcase)
    elsif ent.slug.length <= 4
      initials = ent.slug.upcase
      ent_type = ent.class.name.downcase.to_sym
    else
      initials = ent.name.downcase.gsub(' and ', ' ').gsub(' for ', ' ').gsub(' of ', ' ').gsub(/[^a-z0-9 ]/i, ' ').split(' ')[0..3].map { |w| w[0] }.join('').upcase
      ent_type = ent.class.name.downcase.to_sym
    end
    
    colors = %w(IndianRed YellowGreen   DarkSlateGray   blue Tomato  Chocolate RoyalBlue  LightPink  purple OliveDrab LightSteelBlue  MediumPurple  indigo)
    color = colors[(ent.name.length + ent.id.to_i) % colors.length]
    
    if ent.respond_to?(:avatar_url) && ent.avatar_url.present?
      content_tag(:span, class: "avatar image #{ent_type.to_s}", style: "background-image: url('#{ent.avatar_url}');") do
      end
    else
      content_tag(:span, class: "avatar initials #{ent_type.to_s}", style: "background-color: #{color}") do
        content_tag(:span, class: 'initials') do
          initials
        end
      end
    end
  end
  
end
