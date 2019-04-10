require "rexml/document"

# We have to support both ``` and ~~~.
class Block
    attr_reader :name, :fence

    def initialize(name, fence)
        @name = name
        @fence = fence
    end

    Wave = Block.new("Wave", "~~~")
    Ticks = Block.new("Ticks", "```")

    def self.toStates(path)

        language = File.basename(path, File.extname(path))
        settings = XML.from("#{path}/Contents/Resources/ModeSettings.xml")

        # For each extension, we want to match both the bare extension (extname)
        # as well as a filename with that exenstion (filename.extname). As such,
        # we optionally match any non-newline character string ending in a
        # period, followed by the extension.
        extensions = toRegExpUnion(settings, "settings/recognition/extension")
        withExtensions = extensions.empty? ? "" : "(?:[^\\.\\r\\n]*\\.)?(?:#{extensions})"

        # Exact filenames are easy, just looks for them specifically.
        filenames = toRegExpUnion(settings, "settings/recognition/filename")

        # Add mode specific additions as well
        modegroup = toModeGroup(language)
        
        # Union both together.
        groups = [withExtensions, filenames, modegroup]
            .select { |group| group != "" }
            .map { |group| "(?:#{group})" }
            .join("|")

        # Return both the Wave and Ticks states.
        [Wave, Ticks].map do |block|
            block.toState(language, groups)
        end

    end

    # Generate the <state> tag for a given language and match criteria.
    def toState(language, match)

        # This is a bit complex in order to get the proper highlighting we want.
        # We have an outer state  that matches the code fence up to, but not
        # including, the newline. This makes it so that this begin section is
        # not highlighted. Then, internally, we'll match just the newline.
        beginRegExp = "^#{@fence}(?:#{match})(?:[^\\S\\r\\n][^\\r\\n]*)?(?=[\\r\\n])"
        endRegExp = "^#{@fence}"

        Node.state ({
            "id" => "CodeBlock#{@name}-#{language}",
            "foldable" => "yes",
            "scope" => "meta.codeblock.markdown",
            :children =>
            [
                Node.begin(Node.regex(beginRegExp)),
                Node.end(Node.regex(endRegExp)),
                Node.state({
                    "id" => "CodeBlock#{@name}-#{language}-Code",
                    "usesymbolsfrommode" => language,
                    "useautocompletefrommode" => language,
                    "scope" => "meta.codeblock.#{language}",
                    :children =>
                    [
                        Node.begin({ :children => [Node.regex("[\\r\\n]"), Node.autoend("#{@fence}")] }),
                        Node.end(Node.regex("[\\r\\n](?=#{@fence})")),
                        Node.import("mode" => language)
                    ]
                })
            ]
        })

    end
end

def toModeGroup(language)
    
    result = ["(?i:#{language})"]
    
    case language
        when "Objective-C"
        ["objective_c","objc","objective-c"]
        else
        [language]
    end
    .map{ |term| "(?i:#{term})"}
    .join("|")
end

def toRegExpUnion(xml, match)
    REXML::XPath
        .match(xml, match)
        .map { |element|
            element.attribute("casesensitive").to_s == "yes" ?
                element.text : "(?i:#{element.text})" }
        .join("|")
end

class XML
    def self.from (path)
        file = File.new(path)
        xml = REXML::Document.new(file)
    end
end

class Node

    def self.method_missing(name, items)
        element = REXML::Element.new(name.to_s)
        if (items.is_a? String)
            element.add_text(items)
        elsif (items.instance_of? REXML::Element)
            element.add_element(items)
        else
            items.each do |key, value|
                if key.is_a? String
                    element.add_attribute(key, value)
                elsif (key == :child)
                    element.add_element(child)
                elsif (key == :children)
                    value.each do |child|
                        if child.is_a? String
                            element.add_text(child)
                        else
                            element.add_element(child)
                        end
                    end
                end
            end
        end
        element
    end
end


inputPath = "#{ARGV[0]}/Contents/Resources/SyntaxDefinition.xml"
outputPath = "#{ARGV[1]}/Contents/Resources/SyntaxDefinition.xml"

markdownSyntax = XML.from(inputPath)
parent = markdownSyntax.root.elements["/syntax/states/default"]

excluded = Set[
    # For some reason, including erlang causes SubEthaEdit to crash, some weird
    # recursive state or something?
    "erlang.seemode",

    # For now, don't have rescursive Markdown highlighting, might want to do
    # something clever later though. Currently it's not clear how to end the
    # match since code fences technically match within the nested Markdown.
    "Markdown.seemode"
]

Dir.glob("*.seemode")
    .select { |path| !excluded.include?(path) }
    .each do |path|
        Block::toStates(path).each do |state|
            parent.insert_before("code-blocks", state)
        end
    end
parent.delete_element("code-blocks")

File.open(outputPath, "w") do |file|
    formatter = REXML::Formatters::Default.new(4)
    formatter.write(markdownSyntax, file)
end

