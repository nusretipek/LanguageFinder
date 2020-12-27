using HTTP
using StatsBase

function get_random_wikipedia_page(LANG_CODE::String)
    url = ""
    random_urls = read_dictionary(joinpath(dirname(pathof(LanguageFinder)),"Wikipedia", "Wikipedia_Random.txt"))
    if(haskey(random_urls, LANG_CODE))
        url = "https://" * LANG_CODE * ".wikipedia.org" * random_urls[LANG_CODE]
    else
        homepage = HTTP.get("https://" * LANG_CODE * ".wikipedia.org" * "/wiki/")
        str = homepage.body |> String
        start_point = findfirst("n-randompage", str).stop+3
        text_rest = str[start_point:end]
        random_href = SubString(text_rest, findall("\"", text_rest)[1].start+1, findall("\"", text_rest)[2].start-1)
        push!(random_urls, LANG_CODE => random_href)
        write_dictionary(joinpath(dirname(pathof(LanguageFinder)), "Wikipedia", "Wikipedia_Random.txt"), random_urls)  
        url = "https://" * LANG_CODE * ".wikipedia.org" * random_urls[LANG_CODE] end
    r = HTTP.get(url)
    return r.body |> String
end

function extract_elements(HTML::AbstractString, ELEMENT::String)
    open_p = findall("<"*ELEMENT, HTML)
    close_p = findall("</"*ELEMENT, HTML)
    arr = []
    try
        for i in 1:length(open_p)
            temp_text = SubString(HTML, open_p[i].start, close_p[i].stop+1) 
            push!(arr, temp_text) end catch x end
    return arr
end

function clean_inside_tags(TEXT::AbstractString, SYMBOL_START::String, SYMBOL_STOP::String)
    open_symbol = findall(SYMBOL_START, TEXT)
    close_symbol = findall(SYMBOL_STOP, TEXT)
    arr = []
    if(length(open_symbol) > 0 && length(close_symbol) > 0 && length(open_symbol) == length(close_symbol))
        for i in 1:min(length(open_symbol), length(close_symbol))   
            temp_text = SubString(TEXT, open_symbol[i].start, close_symbol[i].stop)
            push!(arr, temp_text) end end
    for j in arr
        TEXT = replace(TEXT, j => "") end
    return TEXT
end

function clean_text_wiki(HTML::AbstractString)
    temp_text = ""
    for i in extract_elements(HTML, "p")
        temp_text *= clean_inside_tags(clean_inside_tags(clean_inside_tags(clean_inside_tags(i, "<", ">"), "[", "]"), "(", ")"), "{", "}") end
    return temp_text
end

function read_dictionary(InputFile::String)
    f = open(InputFile)
    raw_text = readlines(f)
    close(f)    
    dictionary = Dict()
    for i in raw_text
        push!(dictionary,split(i)[1] => split(i)[2]) end
    return dictionary
end

function write_dictionary(InputFile::String, DICT::Dict)
    f = open(InputFile, "w")
    for (key, value) in DICT
        println(f, key, " ", value) end
    close(f)
end

function build_corpus(LANG_CODE::String, PAGES::Integer, SLEEP_TIME::Integer = 15)
    temp_text = ""
    try
        for i in 1:PAGES
            temp_text *= process_text(clean_text_wiki(get_random_wikipedia_page(LANG_CODE))) * " "
            sleep(SLEEP_TIME) end
    finally
        f = open("corpus/" * LANG_CODE * "_corpus.txt", "a")
        print(f, temp_text)
        close(f) end
end

function process_text(TEXT::String)
    temp_text = replace(TEXT, r"[\n\r\t]" => " ")
    temp_text = replace(temp_text, r"[^\p{L}]" => " ")
    temp_text = replace(temp_text, r"\s\s+" => " ")
    return strip(lowercase(temp_text))
end

function read_corpus(PATH::String)
    s = ""
    open(PATH, "r") do f
        s=read(f, String) end
    return s
end

function count_letter_map(TEXT::SubString)
    counts = Dict{Any,Int64}()
    counts = countmap(collect(TEXT))
    return counts
end

function count_n_grams(TEXT::SubString, n::Integer)
    arr = []
    collection = collect(TEXT)
    for i in 1:length(collection)-n+1
        temp_gram = ""
        for j in 1:n
            temp_gram *= collection[i+j-1] end
            push!(arr, temp_gram) end 
    counts = countmap(arr)
    return counts    
end

function add_count_maps(DICT1::Dict, DICT2::Dict)
    return merge!(+, DICT1, DICT2)
end

function train_corpus(ARR::Array, n::Integer)
    map = Dict()
    map_c = Dict()
    for text in ARR
        input = read_corpus(text)
        if(n == 1) map = count_letter_map(process_text(input))
            else map = count_n_grams(process_text(input), n) end
        if(!isempty(map_c))
            map_c = add_count_maps(map, map_c)
        else
            map_c = map end end
    total_dict = sum(values(map_c))
    for (key,value) in map_c
        if(value < total_dict/10000)
            delete!(map_c, key) end end
    return sort(collect(map_c), by=x->x[2], rev=true)
end

function write_trained_dictionaries()
    corpus_files = readdir("corpus")[2:end]
    for i in corpus_files
        for j in 1:4
            temp_train = train_corpus(["corpus/" * i], j)
            f = open("ngrams/" * string(j) * "/" * SubString(i, 1, 2) * ".txt", "w")
            for (key, value) in temp_train
                println(f, key, ",", value) end
            close(f) end end
end

function train_wikipedia_text(lang_code::String, pages::Integer, sleep_time::Integer = 10)
    try HTTP.get("https://" * lang_code * ".wikipedia.org" * "/wiki/") catch x throw(ArgumentError("Invalid language code; check WP codes in https://en.wikipedia.org/wiki/List_of_Wikipedias")) end
    pages < 1 && throw(DomainError("pages must be integer and more than 0"))
    sleep_time < 0 && throw(DomainError("sleep time must be positive"))
    temp_text = ""
    counter = 0 
    try
        for i in 1:pages
            temp_text *= process_text(clean_text_wiki(get_random_wikipedia_page(lang_code))) * " "
            sleep(sleep_time)
            counter += 1 end
    finally
        f = open(joinpath(dirname(pathof(LanguageFinder)), "Wikipedia", "corpus", (lang_code*"_corpus.txt")), "a")
        print(f, temp_text)
        close(f)
        for j in 1:4
            temp_train = train_corpus([joinpath(dirname(pathof(LanguageFinder)),"Wikipedia", "corpus", (lang_code*"_corpus.txt"))], j)
            f = open(joinpath(dirname(pathof(LanguageFinder)), "Wikipedia", "ngrams", string(j), (lang_code *".txt")), "w")
            for (key, value) in temp_train
                println(f, key, ",", value) end
            close(f) end end
        counter == pages ? println("Successfully trained on ", counter, " ", lang_code, " wikipedia pages.") : println("Early termination due to error, trained on ", counter, " ", lang_code, " wikipedia pages.")
end