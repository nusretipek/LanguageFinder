"""
Wikipedia corpus builder is designed to harvest random Wikipedia pages in a given 
language code such as es for Spanish and train the ngram weights based on these pages. 
The full list of the available languages can be found in https://en.wikipedia.org/wiki/List_of_Wikipedias
## Example
```julia 
julia> train_wikipedia_text("es", 10, 15)
julia> 
    "Successfully trained on 10 es wikipedia pages."
```
"""

using HTTP
using StatsBase


#=
The dictionaries is stored within text files with custom format.
This function reads the custom text format and build a dictionary variable.
Retruns the dictionary read from the text file.
=#

function read_dictionary(InputFile::String)
    f = open(InputFile)
    raw_text = readlines(f)
    close(f)    
    dictionary = Dict()
    for i in raw_text
        push!(dictionary,split(i)[1] => split(i)[2]) end
    return dictionary
end

#=
The dictionaries are written with specific format for later use.
Specifically each line ad key + " " + value. This function writes
a defined dictionary to a text file.
Retruns nothing.
=#

function write_dictionary(InputFile::String, DICT::Dict)
    f = open(InputFile, "w")
    for (key, value) in DICT
        println(f, key, " ", value) end
    close(f)
end

#=
The Wikipedia page request function. Each Wikipedia subdomain has different random page url, instead of 
requesting that url, there is a known random page url text file stored and automatically updated when
a new language WP code is used. ("Wikipedia_Random.txt") 
HTTP library is used to get the webpage and the body text is pipelined to string.
Retruns the String type webpage body text.
=#

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

#=
The raw HTML string is not parsed as a tree and with a lot of standartized HTML tags.
It is necessary to take the useful string in between these tags. The extract element function
checks crawls in the HTML raw string and extract strings.
Retruns an Array of useful strings.
=#

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

#=
The strings removed from the HTML tags are still contaminated with the inline annotations with 
(),[],{} and etc. The text or other information inside is often not useful to train ngrams. 
This function cleans these special set charaters and the information inside.
Retruns a cleared string.
=#

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

#=
This function combines the extracting and cleaning most prominent sets from a random Wikipedia
page. It extract the text within the <p> tags (Always the case in Wikipedia). Then, utilize the 
clean_inside_tags function to clear <>, (), [] and {}.
Returns a String with clean text.
=#

function clean_text_wiki(HTML::AbstractString)
    temp_text = ""
    for i in extract_elements(HTML, "p")
        temp_text *= clean_inside_tags(clean_inside_tags(clean_inside_tags(clean_inside_tags(i, "<", ">"), "[", "]"), "(", ")"), "{", "}") end
    return temp_text
end

#=
The text is further processed by removing \n \r and \t character sequences. Any non-letter 
such as numbers, punctuation and etc. is removed. Lastly, all the spaces with more than 
single space is reduced to a single space. 
Returns a refined string ready to train.
=#

function process_text(TEXT::String)
    temp_text = replace(TEXT, r"[\n\r\t]" => " ")
    temp_text = replace(temp_text, r"[^\p{L}]" => " ")
    temp_text = replace(temp_text, r"\s\s+" => " ")
    return strip(lowercase(temp_text))
end

#=
Count letter map is used to build a unigram frequency dictionary.
The StatsBase countmap is used to extract the frequencies.
Returns a dictionary of counts
=#

function count_letter_map(TEXT::SubString)
    counts = Dict{Any,Int64}()
    counts = countmap(collect(TEXT))
    return counts
end

#=
A similar methodology can be followed for any ngram frequency.
count_n_grams iterates all the text and build a large array of
ngram characters then utilize StatsBase countmap.
Returns a dictionary of counts (ngrams).
=#

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

#=
The function is built for short hand to element-wise additon of 
dictionaries. 
Returns a dictionary where the same key values are combined. 
=#

function add_count_maps(DICT1::Dict, DICT2::Dict)
    return merge!(+, DICT1, DICT2)
end

#=
Read corpus is initially built to serve single purpose, it can read
a text file given a local path.
Returns the string contained in the text file.
=#

function read_corpus(PATH::String)
    s = ""
    open(PATH, "r") do f
        s=read(f, String) end
    return s
end

#=
The train corpus file takes an array as an input and ngram value to train.
The array input is useful to feed in multiple filepaths at once to train locally
with existing text files. It utilize previous functions.
Returns a sorted array of counts given an ngram value.
=#

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

#=
The train_wikipedia_text is the on demand spraping/training fuction.
It takes three parameters lang_code as WP of a Wikipedia page such as
es for Spanish or en for English. The pages is the number of pages to be
train on and lastly sleep time between each page request to not over burden
the Wikipedia servers; initially set to 10 seconds but 3 seconds is managable 
as well. 
It writes (or overwrites) the ngram text files used to detect the language.
Four ngram files are witten after training. Additionally a full corpus file
for later use is added under the corpus folder. 
Returns nothing.
=#

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