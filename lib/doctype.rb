# HAML adds SYSTEM to the DOCTYPE which breaks prince, so we'll write it out ourselves
Webby::Filters.register :doctype do |input, cursor|
  page = cursor.page.is_a?(Webby::Resources::Page) ? cursor.page : cursor.renderer.page
  "<!DOCTYPE html>\n#{input}"
end