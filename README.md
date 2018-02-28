# Bitext Models
## Introduction
Modern SMT systems typically depend on three kinds of models: a language model, a translation model (aka phrase table), and lexicalized reodering model (aka lexicalized distortion model). The latter two require a parallel corpus (aka bitext) to be built. Building those bitext models requires a number of steps:
* Word Alignment: Here word-to-word (but not necessarily one-to-one) links are learned for each parallel sentence pair in the the bitext.
* Word Translation Models: Here models of the form p(w_f|w_e) and p(w_e|w_f) are learned, where w_e and w_f are words.
* Lexicalized Reordering Models: These are models of the form p(Orientation|(p_f,p_e)) where Orientation={monotonic,swap,discontinuous}, where p_f and p_e are phrases.
* Translation Models: These are models of the form p(p_f|p_e) and p(p_e|p_f) , where p_f and p_e are phrases.

## Word Alignment

With our word alignment tool you can do step 1. This is done by calling the following script. The details of the call is covered in the following sections.

    wordAlignment.pl

## Installation 

The word alignment tool works right after being cloned. However, the dependecies should be addressed beforehand.

### Dependencies

Our word alignment tool has dependencies to some files from [MGIZA](https://github.com/moses-smt/mgiza/blob/master/mgizapp/INSTALL) installation. These files include:

* mgiza
* mkcls
* snt2cooc
* snt2coocrmp
* merge_alignment.py

and 

* symal

In order to meet the dependencies, first install MGIZA tool following the [installation instructions](https://github.com/moses-smt/mgiza/blob/master/mgizapp/INSTALL). Then, please copy the first 5 files into the following path:

    [PATH-TO-MODEL-BUILDING-TOOL-HOME]/dependencies/external_binaries
    
and the "symal" file to the following:

    [PATH-TO-MODEL-BUILDING-TOOL-HOME]/dependencies/moses/bin/
    
Now the tool can be used by calling it using the command given in the example below.

## How to Use

A sample calling of the script is as follows:

    [PATH-TO-MODEL-BUILDING-TOOL-HOME]/wordAlignment.pl --dependencies=[PATH-TO-MODEL-BUILDING-TOOL-HOME]/dependencies 
    --corpus=bitext --f=de --e=en --moses-params="--parallel" --alignment-strategies=m1-m5:grow-diag-final-and 
    --lex-probs=m1-m5:grow-diag-final-and --no-batches=2 --no-parallel=2 --mgiza >& err.log


* `--corpus`

Specifies the shared prefix of the names of source and target files. This means that these two input files should have shared prefix in their names. For example 
`bitext.de` and `bitext.en`

* `--f`

Specifies the suffix of the input source file. For example, `--f=de` if the source file name is like `[FILENAME].de`

* `--e`

Specifies the suffix of the input target file. For example, `--e=en` if the target file name is like `[FILENAME].en`



## Translation and Reordering Models

With our model building tool you can do step 2 to 4 assuming that you already have a word aligned parallel corpus in hand. All these steps can be done by a single script. The details of the call is covered in the following sections.
    
    build-models-from-wordAligned-bitext.pl

## Installation

There is no need to install the model building tool itself. It works right after cloning from the repository. However, the dependencies should be addressed beforehand. 

### Dependecies

This model building tool has dependencies to three binary files from [Moses](http://www.statmt.org/moses/?n=Moses.Releases) translation system. These files include:

* consolidate
* extract
* score

In order to meet the dependencies, first install Moses translation tool following the [installation instructions](http://www.statmt.org/moses/?n=Moses.Releases). 

After installation, copy the aforementioned binary files from Moses installation directory to the following path:

    [PATH-TO-MODEL-BUILDING-TOOL-HOME]/dependencies/moses/bin/

Now the tool can be used by calling it using the command given in the example below.

## How to Use
A sample calling of the script is as follows:

    ./build-models-from-wordAligned-bitext.pl --input-files-prefix=aligned 
    --experiment-dir=./expdir  --dependencies=./dependencies --f=chinese --e=english 
    --a=grow-diag-final --build-distortion-model --use-dlr  
    --moses-orientation  --build-phrase-table >& err.log

* `--input-files-prefix`

Specifies the shared prefix of the names of source, target and alignment files. This means that these three input files should have shared prefix in their names. For example 
`aligned.chinese`, `aligned.english` and `aligned.grow-diag-final`.

* `--f`

Specifies the suffix of the input source file. For example, `--f=chinese` if the source file name is like `[FILENAME].chinese`

* `--e`

Specifies the suffix of the input target file. For example, `--e=english` if the target file name is like `[FILENAME].english`

* `--a`

Specifies the suffix of the input alignment file. For example, `--a=grow-diag-final` if the alignment file name is like `[FILENAME].grow-diag-final`

* `--build-distortion-mode`

Flag to build lexicalized reordering model.

* `--use-dlr`

Flag to generate 4 reordering orientations instead of 3 by splitting discontinuous orientation into discontinuous left and discontinuous right.

* `--build-phrase-table`

Flag to create phrase table (translation model).

* `--moses-orientation`

Flag to use moses style orientations to build lexicalized reordering models. The default is to use Oister style which achieves higher BLEU score comparing to moses style. 

* `--dependencies`

Specifies the path to the dependencies folder where other scripts are located. 

This will take some time, depending on the size of the bitext files. If they are small (<2,000 lines, for debuggin purposes), it'll take a few minutes. If they are large (>200,000 lines) it can take several hours. After it has finished, you should see a number of new directories under the path to --experiment-dir.  The most important one is `models/model` which contains the following files:

* `dm_fe_0.75.gz` 

The lexicalized reordering model.

* `lex.e2f` and `lex.f2e` 

The word translation models.

* `phrase-table.gz` 

The translation model.

# Building Language Model
With our model building tool, you can easily build large language model from simple text. This tool provide easy inegration with the well known languge model engine SRILM.

### Dependecies
This tool makes calls to SRILM language modelling toolkit, hence you need to install SRILM before you using this tool. Downlaod the toolkit from (http://www.speech.sri.com/projects/srilm/download.html) and follow the instruction for installtion in INSTALL (http://www.speech.sri.com/projects/srilm/docs/INSTALL) file. 

### Usage 

Large language models can be built by simply running the perl script build-large-lm.pl.  

a sample calling of the script is as follows:

./build-large-lm.pl --text=input.txt --lm=output.lm --srilm-path=/path-to-srilm-directory --order=5 

Detailed arguments are explained as follows : 

* --text

  Specifies the input text file. Input file should contain the sentences one per line.

* --lm

  Specifies the name of the output file.

* --srilm-path

  Specifies the path to srilm top level installation directory

* --order

  Specifies the n-gram order of the language model requied. For example, --order=5 specifies a 5-gram language model. (default=5)

* --working-dir

  This tools creates multiple temporary files while building the langauge model. This option specifies the path to a directory where these temporary files should be stored. The tool deletes the file after the language model is built. (default=working_dir. If no value is provided a temporay directory is built where the script is called)

* --keep-files

  Specifies temporary log files not to be deleted. By default, this tool deletes temporary log files. If you need them for debugging purposes, provide this flag.

* --smoothing

  Smoothing or discounting techniques are used while building language model to account for sparse or rare n-grams. This tool provides two smoothing/discounting techniques. 1. Kneser-Ney smoothing : specified as --smoothing=kneser-ney or --smoothing=kneser-ney=kndiscount 2. Witten-bell smoothing : specified as --smoothing=wbdiscount or --smoothing=-wbdiscount. (default=kndiscount) 

* --no-interpolation

  Specifies no interpolation of the discounted n-gram probability estimates with lower-order estimates. By default, this tool provides for such an interpolation (This sometimes yields better models with some smoothing methods).

* --min-counts

  Sets the minimal count of N-grams of order n that will be included in the LM. All N-grams with frequency lower than that will effectively be discounted to 0. For example, --min-counts=2-2-2-2-2, specifies that for a LM of order 5, the minimum frequency of all n-grams of size 5 or lesser should be 2. Any n-gram with value less that 2 will be considered non-existent. (default=1-1-1-2-2)

* --batch_size

  Specifies number of sentences per batch to be processed. This tool splits the input text in batches and finally combines output of each batch in a single language model. A higher batch size results in higher parallelization and hence builds the LM faster. However, it increases the memory requirement. A lower batch size requires low memory, however, splits data in less number of batches and hence results in slow speed. (default=1000000). Reduce the number of batches if you have memory limitations. 

* --pre-processing

  Specifies different pre-processing options to be applied to the input text before building language model. For example, --pre-processing=lc specifies that text should be converted to lowercase.  This tool by default provides 4 pre-processing operations :     
  1. --pre-processing=lc : All the letters in the text to be lowercased
  2. --pre-processing=numsub : All number should be transliterated. For example '11' should be converted to 'eleven'
  3. --pre-processing=dedupl : Sort and remove duplicate entries from the files.
  4. --pre-processing=sent_tags : Apply tags "<s>" and "</s>" at start and end of each sentence.
  Multiple preprocessing can be applied by providing a comma-seperated list of values for example : --pre-processing=lc,numsub. By default, the tool applies all for pre-processing options i.e default=lc,numsub,dedupl,sent_tags
