using StatsBase

mutable struct LanguageFind
    lang::AbstractString
    function LanguageFind(text::AbstractString, ngram::Integer = 0)
        length(text) < 1 && throw(DomainError("Text is empty"))
        (ngram < 0 || ngram > 4) && throw(DomainError("Ngram is not valid"))
        if(ngram == 0)
            lang = sort(collect(countmap(collect([i for i in [check_language(text, 2),check_language(text, 3),check_language(text, 4)] if i != ""]))), by=x->x[2], rev=true)[1][1]
        else
            lang = check_language(text, ngram) end
        new(lang) 
    end
end

function read_corpus(PATH::String)
    s = ""
    open(PATH, "r") do f
        s=read(f, String) end
    return s
end

function process_text(TEXT::String)
    temp_text = replace(TEXT, r"[\n\r\t]" => " ")
    temp_text = replace(temp_text, r"[^\p{L}]" => " ")
    temp_text = replace(temp_text, r"\s\s+" => " ")
    return strip(lowercase(temp_text))
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

function density_calculate(ARR::Array, CORPUS::Array)
    arr_test = []
    arr_corpus = []
    for i in CORPUS
        pos = findfirst(x->x[1]==i[1], ARR)
        if(pos != nothing) 
            push!(arr_corpus, i[2]) 
            push!(arr_test, ARR[pos][2])
        else                  
            push!(arr_corpus, i[2]) 
            push!(arr_test, 0) end end 
    return arr_test, arr_corpus
end

function density_normalize(ARR::Array)
    arr = []
    temp_sum = 0
    for i in 1:length(ARR)
        temp_sum += ARR[i] end
    for i in 1:length(ARR)
        push!(arr, ARR[i]/temp_sum) end
    return arr
end

function density_calculate_sum(ARR::Array, CORPUS::Array)
    arr_corpus = []
    for i in CORPUS push!(arr_corpus, i[2]) end
    normal_corpus = density_normalize(arr_corpus)
    sum_weight = 0
    for i in 1:length(CORPUS)
        pos = findfirst(x->x[1]==CORPUS[i][1], ARR)
        if(pos != nothing) sum_weight += (ARR[pos][2]*normal_corpus[i]) end end
    return sum_weight
end

function distance_delta(TEXT::String, CORPUS::Array, n::Integer)
    temp_sort = sort(collect(count_n_grams(process_text(TEXT), n)), by=x->x[2], rev=true)
    return density_calculate_sum(temp_sort, CORPUS)
end

function check_language(text::String, ngram::Integer = 3)
    best_score = 0
    lang_code = ""
    ngram_files = readdir(pwd()*"/Wikipedia/ngrams/" * string(ngram))
    for i in ngram_files
        f = open(pwd()*"/Wikipedia/ngrams/" * string(ngram) * "/" * i, "r")
        raw_text = readlines(f)
        close(f)
        dictionary = Dict{Any,Int64}()
        for j in raw_text
            push!(dictionary,split(j, ",")[1] => parse(Int, split(j, ",")[2])) end
        sorted_array = sort(collect(dictionary), by=x->x[2], rev=true)
        temp_distance = distance_delta(text, sorted_array, ngram)
        if(temp_distance > best_score) 
            lang_code = i[1:2] 
            best_score = distance_delta(text, sorted_array, ngram) end end
    return lang_code
end