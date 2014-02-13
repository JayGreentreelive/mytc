module ApplicationHelper
  
  def simplify_html(txt)
  
    Sanitize.clean(txt,
      elements: ['p', 'ul', 'li', 'ol', 'a', 'div', 'h1', 'h2', 'br'],
      attributes: { 'a' => ['href'] }
    ).html_safe
  end  
end
