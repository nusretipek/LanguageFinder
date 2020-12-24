# LanguageFinder

[![Build Status](https://travis-ci.com/nusretipek/LanguageFinder.svg?branch=main)](https://travis-ci.com/nusretipek/LanguageFinder.jl)

*A simple Julia package for language detection using bigrams, trigrams and quadrigrams.*

The Julia package is designed to detect most common languages accurately and train any language that has Wikipedia pages (>200) on demand. It use consensus approach rto guess language rather than only trigrams to improve accuracy. It is the first Julia package that use quadrigrams in language detection.    

## Installation Instructions

```
using Pkg
Pkg.add(url="https://github.com/nusretipek/LanguageFinder")
```

## Basic Usage

```
using LanguageFinder

L = LanguageFinder.LanguageFind
L("This is a ship.", 0).lang
```

The struct takes two parameters; text and ngram. Ngram = 0 is a consensus (of bigram, trigram and quadrigram) and default parameter. It is slower than single ngram evaluation but more accurate. If speed is the concern, ngram parameter can take 1,2,3,4 representing unigram, bigram, trigram and quadrigram check. Trigram and quadrigrams are reliable. Prefer bigrams for languages like Chinese or Japanese where single character represent a word and there are not enough training set. 

There are 25 default languages, each trained from approximately 500 wikipedia articles. The languages included;
1. AR - Arabic
2. CS - Czech
3. DA - Danish
4. DE - German
5. EL - Greek
6. EN - English
7. ES - Spanish
8. FA - Persian
9. FI - Finnish
10. FR - French
11. HE - Hebrew
12. HI - Hindi
13. HU - Hungarian
14. IT - Italian
15. JP - Japanese
16. KO - Korean
17. NL - Dutch
18. NO - Norwegian
19. PL - Polish
20. PT - Portuguese
21. RU - Russian
22. SV - Swedish
23. TR - Turkish
24. UK - Ukrainian
25. ZH - Chinese

## Training New Languages / Improve Existing Weights
In some systems, the package directory may be read only. Make sure that *C:\Users\USERNAME\.julia\packages\LanguageFinder* folder is **not** only read-only. 

```
train_wikipedia_text("eo", 5, 15)
```

The function has three parameters namely language code, number of pages to train and number of seconds to rest. 
Please see [List of Wikipedias](https://en.wikipedia.org/wiki/List_of_Wikipedias) for possible language codes (WP Code). There is no default page number. The default sleep seconds is 15 but can be changed. It is there to make sure that program treats Wikipedia servers fairly. 

The function not only capable to train on new language but one can use it to override the default weights. 

```
train_wikipedia_text("es", 1000, 5)
```

This would override the ngram files of Spanish language by using 1,000 Wikipedia pages instead of 500.  

*If you train your corpus using Wikipedia servers, please consider to support/donate the non-profit orgatization: https://wikimediafoundation.org/support/*
