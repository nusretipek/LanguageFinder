module LanguageFinder

import HTTP
import StatsBase

export LanguageFinder, train_wikipedia_text 

include("Wikipedia/wikipedia_corpus_buid.jl")
include("language_finder.jl")

end #module