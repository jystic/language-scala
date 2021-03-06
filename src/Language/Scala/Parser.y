{

{-# LANGUAGE OverloadedStrings #-}

-- Happy parser for .scala files. The output is a raw parse tree
-- data structure defined in the "Syntax" module.

module Language.Scala.Parser
    ( Grammar
    , parseWith
    , compilationUnitGrammar
    ) where

import           Data.ByteString (ByteString)
import qualified Data.ByteString as B
import qualified Data.ByteString.UTF8 as UTF8
import           Data.Either
import           Data.Functor
import           Data.Maybe
import           Data.String

import           Language.Scala.Context
import           Language.Scala.Position
import           Language.Scala.Syntax
import           Language.Scala.Tokens
import           Language.Scala.Util

}

%name compilationUnitGrammar compilation_unit
%tokentype { Either Position (Contextual Token) }
%monad { Grammar }
%lexer { lexer } { Left _ }
%error { syntaxError }

%token

  nl_token              { Right ($$ @ (Tok_NewLine One    :@@ _)) }
  nls_token             { Right ($$ @ (Tok_NewLine Many   :@@ _)) }

  "abstract"            { Right ($$ @ (Tok_Abstract       :@@ _)) }
  "case"                { Right ($$ @ (Tok_Case           :@@ _)) }
  "catch"               { Right ($$ @ (Tok_Catch          :@@ _)) }
  "class"               { Right ($$ @ (Tok_Class          :@@ _)) }
  "def"                 { Right ($$ @ (Tok_Def            :@@ _)) }
  "do"                  { Right ($$ @ (Tok_Do             :@@ _)) }
  "else"                { Right ($$ @ (Tok_Else           :@@ _)) }
  "extends"             { Right ($$ @ (Tok_Extends        :@@ _)) }
  "false"               { Right ($$ @ (Tok_False          :@@ _)) }
  "final"               { Right ($$ @ (Tok_Final          :@@ _)) }
  "finally"             { Right ($$ @ (Tok_Finally        :@@ _)) }
  "for"                 { Right ($$ @ (Tok_For            :@@ _)) }
  "forSome"             { Right ($$ @ (Tok_ForSome        :@@ _)) }
  "if"                  { Right ($$ @ (Tok_If             :@@ _)) }
  "implicit"            { Right ($$ @ (Tok_Implicit       :@@ _)) }
  "import"              { Right ($$ @ (Tok_Import         :@@ _)) }
  "lazy"                { Right ($$ @ (Tok_Lazy           :@@ _)) }
  "match"               { Right ($$ @ (Tok_Match          :@@ _)) }
  "new"                 { Right ($$ @ (Tok_New            :@@ _)) }
  "null"                { Right ($$ @ (Tok_Null           :@@ _)) }
  "object"              { Right ($$ @ (Tok_Object         :@@ _)) }
  "override"            { Right ($$ @ (Tok_Override       :@@ _)) }
  "package"             { Right ($$ @ (Tok_Package        :@@ _)) }
  "private"             { Right ($$ @ (Tok_Private        :@@ _)) }
  "protected"           { Right ($$ @ (Tok_Protected      :@@ _)) }
  "return"              { Right ($$ @ (Tok_Return         :@@ _)) }
  "sealed"              { Right ($$ @ (Tok_Sealed         :@@ _)) }
  "super"               { Right ($$ @ (Tok_Super          :@@ _)) }
  "this"                { Right ($$ @ (Tok_This           :@@ _)) }
  "throw"               { Right ($$ @ (Tok_Throw          :@@ _)) }
  "trait"               { Right ($$ @ (Tok_Trait          :@@ _)) }
  "try"                 { Right ($$ @ (Tok_Try            :@@ _)) }
  "true"                { Right ($$ @ (Tok_True           :@@ _)) }
  "type"                { Right ($$ @ (Tok_Type           :@@ _)) }
  "val"                 { Right ($$ @ (Tok_Val            :@@ _)) }
  "var"                 { Right ($$ @ (Tok_Var            :@@ _)) }
  "while"               { Right ($$ @ (Tok_While          :@@ _)) }
  "with"                { Right ($$ @ (Tok_With           :@@ _)) }
  "yield"               { Right ($$ @ (Tok_Yield          :@@ _)) }

  "("                   { Right ($$ @ (Tok_LParen         :@@ _)) }
  ")"                   { Right ($$ @ (Tok_RParen         :@@ _)) }
  "["                   { Right ($$ @ (Tok_LBracket       :@@ _)) }
  "]"                   { Right ($$ @ (Tok_RBracket       :@@ _)) }
  "{"                   { Right ($$ @ (Tok_LBrace         :@@ _)) }
  "}"                   { Right ($$ @ (Tok_RBrace         :@@ _)) }
  "."                   { Right ($$ @ (Tok_Dot            :@@ _)) }
  ","                   { Right ($$ @ (Tok_Comma          :@@ _)) }
  ";"                   { Right ($$ @ (Tok_Semi           :@@ _)) }
  "_"                   { Right ($$ @ (Tok_Underscore     :@@ _)) }
  ":"                   { Right ($$ @ (Tok_Colon          :@@ _)) }
  "="                   { Right ($$ @ (Tok_Equals         :@@ _)) }
  "=>"                  { Right ($$ @ (Tok_Arrow          :@@ _)) }
  "<-"                  { Right ($$ @ (Tok_BackArrow      :@@ _)) }
  "<:"                  { Right ($$ @ (Tok_LowerBound     :@@ _)) }
  "<%"                  { Right ($$ @ (Tok_ViewBound      :@@ _)) }
  ">:"                  { Right ($$ @ (Tok_UpperBound     :@@ _)) }
  "#"                   { Right ($$ @ (Tok_Projection     :@@ _)) }
  "@"                   { Right ($$ @ (Tok_Annotation     :@@ _)) }

  "-"                   { Right ($$ @ (Tok_Op         "-" :@@ _)) }
  "+"                   { Right ($$ @ (Tok_Op         "+" :@@ _)) }
  "*"                   { Right ($$ @ (Tok_Op         "*" :@@ _)) }
  "~"                   { Right ($$ @ (Tok_Op         "~" :@@ _)) }
  "!"                   { Right ($$ @ (Tok_Op         "!" :@@ _)) }
  "|"                   { Right ($$ @ (Tok_Op         "|" :@@ _)) }

  op_token              { Right ($$ @ (Tok_Op           _ :@@ _)) }
  varid_token           { Right ($$ @ (Tok_VarId        _ :@@ _)) }
  plainid_token         { Right ($$ @ (Tok_PlainId      _ :@@ _)) }
  stringid_token        { Right ($$ @ (Tok_StringId     _ :@@ _)) }

  int_token             { Right ($$ @ (Tok_Int          _ :@@ _)) }
  long_token            { Right ($$ @ (Tok_Long         _ :@@ _)) }
  float_token           { Right ($$ @ (Tok_Float      _ _ :@@ _)) }
  double_token          { Right ($$ @ (Tok_Double     _ _ :@@ _)) }
  char_token            { Right ($$ @ (Tok_Char         _ :@@ _)) }
  string_token          { Right ($$ @ (Tok_String       _ :@@ _)) }
  symbol_token          { Right ($$ @ (Tok_Symbol       _ :@@ _)) }

%%

--
-- semi-colon / newlines
--

semi_opt :: { Maybe (Contextual ()) }:
    semi                                    { Just $1 }
  | {- empty -}                             { Nothing }

semi :: { Contextual () }:
    ";"                                     { () <\$ $1 }
  | nl_token                                { () <\$ $1 }
  | nls_token                               { () <\$ $1 }

nl_opt :: { Maybe (Contextual ()) }:
    nl_token                                { Just (() <\$ $1) }
  | {- empty -}                             { Nothing          }

nls :: { Maybe (Contextual ()) }:
    nl_token                                { Just (() <\$ $1) }
  | nls_token                               { Just (() <\$ $1) }
  | {- empty -}                             { Nothing          }

--
-- literals
--

literal :: { Contextual Literal }:
    signed_int_literal                      { Lit_Int              <\$> $1 }
  | signed_long_literal                     { Lit_Long             <\$> $1 }
  | signed_float_literal                    { (uncurry Lit_Float)  <\$> $1 }
  | signed_double_literal                   { (uncurry Lit_Double) <\$> $1 }
  | boolean_literal                         { Lit_Boolean          <\$> $1 }
  | character_literal                       { Lit_Character        <\$> $1 }
  | string_literal                          { Lit_String           <\$> $1 }
  | symbol_literal                          { Lit_Symbol           <\$> $1 }
  | "null"                                  { Lit_Null             <\$  $1 }

--
-- integer literals
--

signed_int_literal :: { Contextual Integer }:
    int_literal                             { $1 }
  | "-" int_literal                         { context $1 <@@ (negate <\$> $2) }

int_literal :: { Contextual Integer }:
    int_token                               { integerTokenValue <\$> $1 }

signed_long_literal :: { Contextual Integer }:
    long_literal                            { $1 }
  | "-" long_literal                        { context $1 <@@ (negate <\$> $2) }

long_literal :: { Contextual Integer }:
    long_token                              { integerTokenValue <\$> $1 }


--
-- floating-point literals
--

signed_float_literal :: { Contextual (Integer, Integer) }:
    float_literal                           { $1 }
  | "-" float_literal                       { context $1 <@@ (negateFloat <\$> $2) }

float_literal :: { Contextual (Integer, Integer) }:
    float_token                             { floatTokenValue <\$> $1 }

signed_double_literal :: { Contextual (Integer, Integer) }:
    double_literal                          { $1 }
  | "-" double_literal                      { context $1 <@@ (negateFloat <\$> $2) }

double_literal :: { Contextual (Integer, Integer) }:
    double_token                            { floatTokenValue <\$> $1 }

--
-- boolean literals
--

boolean_literal :: { Contextual Bool }:
    "true"                                  { True  :@@ context $1 }
  | "false"                                 { False :@@ context $1 }

--
-- string literals
--

character_literal :: { Contextual Char }:
    char_token                              { charTokenValue <\$> $1 }

string_literal :: { Contextual ByteString }:
    string_token                            { stringTokenValue <\$> $1 }

symbol_literal :: { Contextual ByteString }:
    symbol_token                            { stringTokenValue <\$> $1 }

--
-- simple identifiers
--

op :: { Contextual Ident }:
    op_token                                { identTokenValue <\$> $1 }

varid :: { Contextual Ident }:
    varid_token                             { identTokenValue <\$> $1 }

plainid :: { Contextual Ident }:
    plainid_token                           { identTokenValue <\$> $1 }
  | varid                                   { $1 }
  | op                                      { $1 }

id :: { Contextual Ident }:
    plainid                                 { $1 }
  | stringid_token                          { identTokenValue <\$> $1 }


qual_id :: { Contextual QualId }:
    id                                      { PHead $1 :@@ between $1 $1 }
  | qual_id "." id                          { (value $1 ::: $3) :@@ between $1 $3 }

ids :: { Contextual Ids }:
    id                                      { PHead $1 :@@ between $1 $1 }
  | ids "," id                              { (value $1 ::: $3) :@@ between $1 $3 }

id_wild :
    id                                      { undefined }
 | "_"                                      { undefined }

id_this :
    id                                      { undefined }
 | "this"                                   { undefined }

--
-- paths & stable identifiers
--

path :
    stable_id                               { undefined }
  | id_prefix_opt "this"                    { undefined }

stable_id :
    id stable_id_suffix_opt                                    { undefined }
  | id_prefix_opt "this" stable_id_suffix                      { undefined }
  | id_prefix_opt "super" class_qualifier_opt stable_id_suffix { undefined }

id_prefix_opt :
    id_prefix                               { undefined }
  | {- empty -}                             { undefined }

id_prefix :
    id "."                                  { undefined }

stable_id_suffix_opt :
    stable_id_suffix                        { undefined }
  | {- empty -}                             { undefined }

stable_id_suffix :
    "." id stable_id_suffix_opt             { undefined }

class_qualifier_opt :
    class_qualifier                         { undefined }
  | {- empty -}                             { undefined }

class_qualifier :
    "[" id "]"                              { undefined }

--
-- type identifiers
--

type :
    function_arg_types "=>" type        { undefined }
  | infix_type existential_clause_opt   { undefined }

function_arg_types :
    infix_type                          { undefined }
  | "(" param_types_opt ")"             { undefined }

param_types_opt :
    param_types                         { undefined }
  | {- empty -}                         { undefined }

param_types :
    param_type                          { undefined }
  | param_types "," param_type          { undefined }

existential_clause_opt :
    existential_clause                  { undefined }
  | {- empty -}                         { undefined }

existential_clause :
    "forSome" "{" existential_dcls "}"  { undefined }

existential_dcls :
    existential_dcl                       { undefined }
  | existential_dcls semi existential_dcl { undefined }

existential_dcl :
    "type" type_dcl                     { undefined }
  | "val" val_dcl                       { undefined }

infix_type :
    compound_type                       { undefined }
  | infix_type id nl_opt compound_type  { undefined }

compound_type :
    annot_types refinement_opt          { undefined }
  | refinement                          { undefined }

annot_types :
    annot_type                          { undefined }
  | annot_types "with" annot_type       { undefined }

annot_type :
    simple_type                         { undefined }
  | annot_type annotation               { undefined }

simple_type :
    simple_type type_args               { undefined }
  | simple_type "#" id                  { undefined }
  | stable_id                           { undefined }
  | path "." "type"                     { undefined }
  | "(" types ")"                       { undefined }

type_args :
    "[" types "]"                       { undefined }

types :
    type                                { undefined }
  | types "," type                      { undefined }

refinement_opt :
    refinement                          { undefined }
  | {- empty -}                         { undefined }

refinement :
    nl_opt "{" refinement_stats "}"     { undefined }

refinement_stats :
    refinement_stat                       { undefined }
  | refinement_stats semi refinement_stat { undefined }

refinement_stat :
    dcl                                 { undefined }
  | "type" type_def                     { undefined }
  | {- empty -}                         { undefined }

type_pat :
    type                                { undefined }

ascription_opt :
   ascription                           { undefined }
 | {- empty -}                          { undefined }

ascription :
    ":" infix_type                      { undefined }
  | ":" annotation annotations          { undefined }
  | ":" "_" "*"                         { undefined }

--
-- expressions
--

exprs_opt :
    exprs                               { undefined }
  | {- empty -}                         { undefined }

exprs_comma_opt :
    exprs ","                           { undefined }
  | {- empty -}                         { undefined }

exprs :
    expr                                { undefined }
  | exprs "," expr                      { undefined }

expr_opt :
    expr                                { undefined }
  | {- empty -}                         { undefined }

expr :
         bindings "=>" expr             { undefined }
  | "implicit" id "=>" expr             { undefined }
  |           "_" "=>" expr             { undefined }
  | expr1                               { undefined }

expr1 :
    "if"    "(" expr  ")" nls expr else_expr_opt        { undefined }
  | "while" "(" expr  ")" nls expr                      { undefined }
  | "try"   "{" block "}" catch_opt finally_opt         { undefined }
  | "do" expr semi_opt "while" "(" expr ")"             { undefined }
  | "for" "(" enumerators ")" nls "yield" expr          { undefined }
  | "for" "{" enumerators "}" nls "yield" expr          { undefined }
  | "throw" expr                                        { undefined }
  | "return" expr_opt                                   { undefined }
  | simple_expr_prefix_opt id equals_expr               { undefined }
  | simple_expr1 argument_exprs equals_expr             { undefined }
  | postfix_expr ascription_opt                         { undefined }
  | postfix_expr "match" "{" case_clauses "}"           { undefined }

else_expr_opt :
    else_expr                           { undefined }
  | {- empty -}                         { undefined }

else_expr :
    semi_opt "else" expr                { undefined }

catch_opt :
    catch                               { undefined }
  | {- empty -}                         { undefined }

catch :
    "catch" "{" case_clauses "}"        { undefined }

finally_opt :
    finally                             { undefined }
  | {- empty -}                         { undefined }

finally :
    "finally" expr                      { undefined }

equals_expr_opt :
    equals_expr                         { undefined }
  | {- empty -}                         { undefined }

equals_expr :
    "=" expr                            { undefined }

postfix_expr :
    infix_expr postfix_expr_id_opt      { undefined }

postfix_expr_id_opt :
    id nl_opt                           { undefined }
  | {- empty -}                         { undefined }

infix_expr :
    prefix_expr                         { undefined }
  | infix_expr id nl_opt infix_expr     { undefined }

prefix_expr :
    "-" simple_expr                     { undefined }
  | "+" simple_expr                     { undefined }
  | "~" simple_expr                     { undefined }
  | "!" simple_expr                     { undefined }

simple_expr :
    "new" class_template                { undefined }
  | "new" template_body                 { undefined }
  | block_expr                          { undefined }
  | simple_expr1 underscore_opt         { undefined }

underscore_opt :
    "_"                                 { undefined }
  | {- empty -}                         { undefined }

simple_expr_prefix_opt :
    simple_expr_prefix                  { undefined }
  | {- empty -}                         { undefined }

simple_expr_prefix :
    simple_expr "."                     { undefined }

simple_expr1 :
    literal                             { undefined }
  | path                                { undefined }
  | "_"                                 { undefined }
  | "(" exprs_opt ")"                   { undefined }
  | simple_expr "." id                  { undefined }
  | simple_expr type_args               { undefined }
  | simple_expr1 argument_exprs         { undefined }

argument_exprs_many :
    argument_exprs_many argument_exprs  { undefined }
  | {- empty -}                         { undefined }

argument_exprs :
    "(" exprs_opt ")"                                   { undefined }
  | "(" exprs_comma_opt postfix_expr ":" "_" "*" ")"    { undefined }
  | nl_opt block_expr                                   { undefined }

--
-- blocks
--

block_expr :
    "{" case_clauses "}"                { undefined }
  | "{" block "}"                       { undefined }

block :
    block_stats result_expr_opt         { undefined }

block_stats :
    block_stats block_stat semi         { undefined }
  | {- empty -}                         { undefined }

block_stat :
    "import"                                    { undefined }
  | annotations "implicit" def                  { undefined }
  | annotations "lazy"     def                  { undefined }
  | annotations local_modifiers tmpl_def        { undefined }
  | expr1                                       { undefined }
  | {- empty -}                                 { undefined }

--
-- patterns
--

result_expr_opt :
    result_expr                         { undefined }
  | {- empty -}                         { undefined }

result_expr :
    expr1                                          { undefined }
  |                          bindings "=>" block   { undefined }
  | implicit_opt id ":" compound_type "=>" block   { undefined }
  |             "_" ":" compound_type "=>" block   { undefined }

implicit_opt :
    "implicit"                          { undefined }
  | {- empty -}                         { undefined }

enumerators :
    generator enumerators_suffix        { undefined }

enumerators_suffix :
    enumerators_suffix semi enumerator  { undefined }
  | {- empty -}                         { undefined }

enumerator :
    generator                           { undefined }
  | guard                               { undefined }
  | pattern1 "=" expr                   { undefined }

generator :
    pattern1 "<-" expr guard_opt        { undefined }

case_clauses :
    case_clause                         { undefined }
  | case_clauses case_clause            { undefined }

case_clause :
    "case" pattern guard_opt "=>" block { undefined }

guard_opt :
    guard                               { undefined }
  | {- empty -}                         { undefined }

guard :
    "if" postfix_expr                   { undefined }

pattern :
    pattern1                            { undefined }
  | pattern "|" pattern1                { undefined }

pattern1 :
    varid ":" type_pat                  { undefined }
  |   "_" ":" type_pat                  { undefined }
  | pattern2                            { undefined }

pattern2 :
    varid at_pattern3_opt               { undefined }
  | pattern3                            { undefined }

at_pattern3_opt :
    at_pattern3                         { undefined }
  | {- empty -}                         { undefined }

at_pattern3 :
    "@" pattern3                        { undefined }

pattern3 :
    simple_pattern                      { undefined }
  | pattern3 pattern3_suffix            { undefined }

pattern3_suffix :
    pattern3_suffix id nl_opt simple_pattern    { undefined }
  | {- empty -}                                 { undefined }

simple_pattern :
    "_"                                                         { undefined }
  | varid                                                       { undefined }
  | literal                                                     { undefined }
  | stable_id                                                   { undefined }
  | stable_id "(" patterns_opt ")"                              { undefined }
  | stable_id "(" patterns_comma_opt varid_at_opt "_" "*" ")"   { undefined }
  | "(" patterns_opt ")"                                        { undefined }

varid_at_opt :
    varid "@"                           { undefined }
  | {- empty -}                         { undefined }

patterns_opt :
    patterns                            { undefined }
  | {- empty -}                         { undefined }

patterns_comma_opt :
    patterns ","                        { undefined }
  | {- empty -}                         { undefined }

patterns :
    pattern                             { undefined }
  | patterns "," pattern                { undefined }
  | "_" "*"                             { undefined }

--
-- parameters
--

type_param_clause_opt :
    type_param_clause                   { undefined }
  | {- empty -}                         { undefined }

type_param_clause :
    "[" variant_type_params "]"         { undefined }

variant_type_params :
    variant_type_param                              { undefined }
  | variant_type_params "," variant_type_param      { undefined }

variant_type_param :
    annotations variant_opt type_param  { undefined }

variant_opt :
    "+"                                 { undefined }
  | "-"                                 { undefined }
  | {- empty -}                         { undefined }

fun_type_param_clause_opt :
    fun_type_param_clause               { undefined }
  | {- empty -}                         { undefined }

fun_type_param_clause :
    "[" type_params "]"                 { undefined }

type_params :
    type_param                          { undefined }
  | type_params "," type_param          { undefined }

type_param :
    id_wild type_param_clause_opt
            upper_bound_opt
            lower_bound_opt
            view_bounds
            context_bounds              { undefined }

has_type_opt :
    has_type                            { undefined }
  | {- empty -}                         { undefined }

has_type :
    ":" type                            { undefined }

lower_bound_opt :
    lower_bound                         { undefined }
  | {- empty -}                         { undefined }

lower_bound :
    ">:" type                           { undefined }

upper_bound_opt :
    upper_bound                         { undefined }
  | {- empty -}                         { undefined }

upper_bound :
    "<:" type                           { undefined }

view_bounds :
    view_bounds view_bound              { undefined }
  | {- empty -}                         { undefined }

view_bound :
    "<%" type                           { undefined }

context_bounds :
    context_bounds has_type             { undefined }
  | {- empty -}                         { undefined }

param_clauses :
    param_clause_many param_clauses_suffix_opt      { undefined }

param_clauses_suffix_opt :
    param_clauses_suffix                { undefined }
  | {- empty -}                         { undefined }

param_clauses_suffix :
    nl_opt "(" "implicit" params ")"    { undefined }

param_clause_many :
    param_clause_many param_clause      { undefined }
  | {- empty -}                         { undefined }

param_clause :
    nl_opt "(" params_opt ")"           { undefined }

params_opt :
    params                              { undefined }
  | {- empty -}                         { undefined }

params :
    param                               { undefined }
  | params "," param                    { undefined }

param :
    annotations id param_type_opt default_opt  { undefined }

param_type_opt :
    ":" param_type                      { undefined }
  | {- empty -}                         { undefined }

default_opt :
    "=" expr                            { undefined }
  | {- empty -}                         { undefined }

param_type :
    type                                { undefined }
  | "=>" type                           { undefined }
  | type "*"                            { undefined }

class_param_clauses :
    class_param_clause_many
    class_param_clauses_suffix_opt      { undefined }

class_param_clause_many :
    class_param_clause_many class_param_clause      { undefined }
  | {- empty -}                                     { undefined }

class_param_clauses_suffix_opt :
    class_param_clauses_suffix                      { undefined }
  | {- empty -}                                     { undefined }

class_param_clauses_suffix :
    nl_opt "(" "implicit" class_params ")"          { undefined }

class_param_clause :
    nl_opt "(" class_params_opt ")"                 { undefined }

class_params_opt :
    class_params                                    { undefined }
  | {- empty -}                                     { undefined }

class_params :
    class_param                                     { undefined }
  | class_params "," class_param                    { undefined }

class_param :
    annotations class_param_prefix_opt
    id ":" param_type equals_expr_opt               { undefined }

class_param_prefix_opt :
    class_param_prefix                              { undefined }
  | {- empty -}                                     { undefined }

class_param_prefix :
    modifiers "val"                                 { undefined }
  | modifiers "var"                                 { undefined }
  | {- empty -}                                     { undefined }

bindings :
    "(" binding_many ")"                            { undefined }

binding_many :
    binding                                         { undefined }
  | binding_many "," binding_many                   { undefined }

binding :
    id_wild has_type_opt                            { undefined }

--
-- modifiers
--

modifiers :
    modifiers modifier                  { undefined }
  | {- empty -}                         { undefined }

modifier :
    local_modifier                      { undefined }
  | access_modifier                     { undefined }
  | "override"                          { undefined }

local_modifiers :
    local_modifiers local_modifier      { undefined }
  | {- empty -}                         { undefined }

local_modifier :
    "abstract"                          { undefined }
  | "final"                             { undefined }
  | "sealed"                            { undefined }
  | "implicit"                          { undefined }
  | "lazy"                              { undefined }

access_modifier_opt :
    access_modifier                     { undefined }
  | {- empty -}                         { undefined }

access_modifier :
    "private"   access_qualifier_opt    { undefined }
  | "protected" access_qualifier_opt    { undefined }

access_qualifier_opt :
    access_qualifier                    { undefined }
  | {- empty -}                         { undefined }

access_qualifier :
    "[" id_this "]"                     { undefined }

--
-- annotations
--

annotations :
    annotations annotation                  { undefined }
  | {- empty -}                             { undefined }

constr_annotations :
    constr_annotations constr_annotation    { undefined }
  | {- empty -}                             { undefined }

annotation :
    "@" simple_type argument_exprs_many     { undefined }

constr_annotation :
    "@" simple_type argument_exprs          { undefined }

name_value_pair :
    "val" id "=" prefix_expr                { undefined }

--
-- templates
--

template_body_opt :
    template_body                                   { undefined }
  | {- empty -}                                     { undefined }

template_body :
    nl_opt "{" self_type_opt template_stats "}"     { undefined }

template_stats :
    template_stat                                   { undefined }
  | template_stats semi template_stat               { undefined }

template_stat :
    import                                          { undefined }
  | annotation_nls modifiers def                    { undefined }
  | annotation_nls modifiers dcl                    { undefined }
  | expr                                            { undefined }
  | {- empty -}                                     { undefined }

annotation_nls :
    annotation_nls annotation_nl                    { undefined }
  | {- empty -}                                     { undefined }

annotation_nl :
    annotation nl_opt                               { undefined }

self_type_opt :
    self_type                                       { undefined }
  | {- empty -}                                     { undefined }

self_type :
    id has_type_opt "=>"                            { undefined }
  | "this" ":" type "=>"                            { undefined }

--
-- imports
--

import :
    "import" import_exprs                           { undefined }

import_exprs :
    import_expr                                     { undefined }
  | import_exprs "," import_expr                    { undefined }

import_expr :
    stable_id "." id_wild_selectors                 { undefined }

id_wild_selectors :
    id_wild                                         { undefined }
  | import_selectors                                { undefined }

import_selectors :
    "{" import_selector_commas import_selector_wild "}"     { undefined }

import_selector_commas :
    import_selector_commas import_selector_comma            { undefined }
  | {- empty -}                                             { undefined }

import_selector_comma :
    import_selector ","                             { undefined }

import_selector_wild :
    import_selector                                 { undefined }
  | "_"                                             { undefined }

import_selector :
    id rename_id_wild_opt                           { undefined }

rename_id_wild_opt :
    rename_id_wild                                  { undefined }
  | {- empty -}                                     { undefined }

rename_id_wild :
    "=>" id_wild                                    { undefined }

--
-- declarations
--

dcl :
    "val" val_dcl                       { undefined }
  | "var" var_dcl                       { undefined }
  | "def" fun_dcl                       { undefined }
  | "type" nls type_dcl                 { undefined }

val_dcl :
    ids has_type                        { undefined }

var_dcl :
    ids has_type                        { undefined }

fun_dcl :
    fun_sig has_type_opt                { undefined }

fun_sig :
    id fun_type_param_clause_opt param_clauses                  { undefined }

type_dcl :
    id type_param_clause_opt upper_bound_opt lower_bound_opt    { undefined }

--
-- definitions
--

pat_var_def :
    "val" pat_def                       { undefined }
  | "var" var_def                       { undefined }

def :
    pat_var_def                         { undefined }
  | "def" fun_def                       { undefined }
  | "type" nls type_def                 { undefined }
  | tmpl_def                            { undefined }

pat_def :
    pat_def_prefix has_type_opt equals_expr     { undefined }

pat_def_prefix :
    pattern2                            { undefined }
  | pat_def_prefix "," pattern2         { undefined }

var_def :
    pat_def                             { undefined }
  | ids has_type "=" "_"                { undefined }

fun_def :
    fun_sig has_type_opt equals_expr                    { undefined }
  | fun_sig nl_opt "{" block "}"                        { undefined }
  | "this" param_clause param_clauses fun_def_suffix    { undefined }

fun_def_suffix :
    "=" constr_expr                     { undefined }
  | nl_opt constr_block                 { undefined }

type_def :
    id type_param_clause_opt "=" type   { undefined }

tmpl_def :
           "class"  class_def           { undefined }
  | "case" "class"  class_def           { undefined }
  |        "object" object_def          { undefined }
  | "case" "object" object_def          { undefined }
  |        "trait"  trait_def           { undefined }

class_def :
    id type_param_clause_opt
       constr_annotations
       access_modifier_opt
       class_param_clauses
       class_template_opt               { undefined }

trait_def :
    id type_param_clause_opt
       trait_template_opt               { undefined }

object_def :
    id class_template_opt               { undefined }

extends_opt :
    "extends"                           { undefined }
  | {- empty -}                         { undefined }

class_template_opt :
    "extends" class_template            { undefined }
  | extends_opt template_body           { undefined }
  | {- empty -}                         { undefined }

trait_template_opt :
    "extends" trait_template            { undefined }
  | extends_opt template_body           { undefined }
  | {- empty -}                         { undefined }

class_template :
    early_defs_opt class_parents template_body_opt      { undefined }

trait_template :
    early_defs_opt trait_parents template_body_opt      { undefined }

class_parents :
    constr with_annot_types             { undefined }

trait_parents :
    annot_type with_annot_types         { undefined }

with_annot_types :
    with_annot_types "with" annot_type  { undefined }
  | {- empty -}                         { undefined }

constr :
    annot_type argument_exprs_many      { undefined }

early_defs_opt :
    early_defs                          { undefined }
  | {- empty -}                         { undefined }

early_defs :
    "{" early_def_many_opt "}" "with"       { undefined }

early_def_many_opt :
    early_def_many                          { undefined }
  | {- empty -}                             { undefined }

early_def_many :
    early_def                               { undefined }
  | early_def_many semi early_def           { undefined }

early_def :
    annotation_nls modifiers pat_var_def    { undefined }

--
-- constructors
--

constr_expr :
    self_invocation                             { undefined }
  | constr_block                                { undefined }

constr_block :
    "{" self_invocation semi_block_stats "}"    { undefined }

semi_block_stats :
    semi_block_stats semi block_stat            { undefined }
  | {- empty -}                                 { undefined }

self_invocation :
    "this" argument_exprs argument_exprs_many   { undefined }

--
-- top level
--

top_stat_seq :
    top_stat                                    { undefined }
  | top_stat_seq semi top_stat                  { undefined }

top_stat :
    annotation_nls modifiers tmpl_def           { undefined }
  | import                                      { undefined }
  | packaging                                   { undefined }
  | package_object                              { undefined }
  | {- empty -}                                 { undefined }

packaging :
    "package" qual_id nl_opt "{" top_stat_seq "}"   { undefined }

package_object :
    "package" "object" object_def               { undefined }

package_stat :
    "package" qual_id semi                      { undefined }

package_stats :
    package_stats package_stat                  { undefined }
  | {- empty -}                                 { undefined }

compilation_unit :
    package_stats top_stat_seq                  { undefined }

{

newtype Grammar a = G { unwrap :: G a }
type G a = Tokens -> List PosError -> (Maybe a, List PosError)
type PosError = Positioned Error

instance Monad Grammar where
  m >>= k = G $ bindG m k
  return x = G $ \ ts es -> (Just x, es)

bindG :: Grammar a -> (a -> Grammar b) -> G b
bindG m k ts es = (my, es1)
  where
    (mx, es1) = unwrap m ts es2
    (my, es2) = maybe (Nothing, es) (\x -> unwrap (k x) ts es) mx

lexer :: (Either Position (Contextual Token) -> Grammar a) -> Grammar a
lexer k = G act
  where
    act (t ::> ts)        es = unwrap (k $ Right t) ts es
    act (e ::! ts)        es = let (mx, es') = act ts es in (mx, e:es')
    act eof@(EndTokens p) es = unwrap (k (Left p)) eof es

panic :: PosError -> Grammar a
panic e = G $ \ ts es -> (Nothing, [e])

syntaxError :: Either Position (Contextual Token) -> Grammar a
syntaxError t = panic ("Syntax error" :@ either position position t)

parseWith :: Grammar a -> Tokens -> Either (List PosError) a
parseWith g ts = maybe (Left es) (\r -> if null es then Right r else Left es) mr
  where
    (mr, es) = unwrap g ts []

}
