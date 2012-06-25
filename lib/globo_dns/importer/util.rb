String.class_eval do
    def strip_quotes
        self.sub(/^['"]?(.*?)['"]?$/, '\1')
    end
end

Citrus::Match.class_eval do
    def delete_from(parent)
        captures.clear
        matches.clear
        puts "indeed! parent.matches includes it!" if parent.matches.include?(self)
        parent.matches.delete(self)
        parent.captures.each do |key, value|
            puts "indeed! parent.captures[#{key}] is it!" if value.object_id == self.object_id
            parent.captures[key] = value = nil if value.object_id == self.object_id
            puts "indeed! parent.captures[#{key}] includes it!" if value.is_a?(Array) && value.include?(self)
            parent.captures[key].delete(self)  if value.is_a?(Array) && value.include?(self)
        end
    end
end
