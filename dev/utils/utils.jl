
macro expect(pred)
    quote
        ($pred) ? nothing : error("expected: ($string(pred)) == true")
    end
end
