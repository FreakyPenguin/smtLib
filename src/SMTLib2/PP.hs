module SMTLib2.PP where

import SMTLib2.AST
import Text.PrettyPrint
import Numeric

class PP t where
  pp :: t -> Doc

instance PP Bool where
  pp True   = text "true"
  pp False  = text "false"

instance PP Integer where
  pp        = integer

ppString :: String -> Doc
ppString = text . show

instance PP Name where
  pp (N x) = text x

instance PP Attr where
  pp (Attr x v) = char ':' <> pp x <+> maybe empty pp v

instance PP Quant where
  pp Forall = text "forall"
  pp Exists = text "exists"

instance PP QName where
  pp (Name x)         = pp x
  pp (TypedName x t)  = parens (text "as" <+> pp x <+> pp t)


instance PP Expr where
  pp expr =
    case expr of

      Lit l     -> pp l

      App c ts  ->
        case ts of
          [] -> pp c
          _  -> parens (pp c <+> fsep (map pp ts))

      Quant q bs e ->
        case bs of
          [] -> pp e
          _  -> parens (pp q <+> parens (fsep (map pp bs)) $$ nest 2 (pp e))

      Let ds e ->
        case ds of
          [] -> pp e
          _  -> parens (text "let" <+> (parens (vcat (map pp ds)) $$ pp e))

      Annot e as ->
        case as of
          [] -> pp e
          _  -> parens (char '!' <+> pp e $$ nest 2 (vcat (map pp as)))


instance PP Binder where
  pp (Bind x t) = parens (pp x <+> pp t)

instance PP Defn where
  pp (Defn x e)   = parens (pp x <+> pp e)

instance PP Type where
  pp ty =
    case ty of
      TApp c ts ->
        case ts of
          [] -> pp c
          _  -> parens (pp c <+> fsep (map pp ts))
      TVar x -> pp x

instance PP Literal where
  pp lit =
    case lit of

      LitNum n fmt ->
        case fmt of
          Dec -> integer n
          Hex -> text "#x" <> text (showHex n "")
          Bin -> text "#b" <> text (showIntAtBase 2 (head . show) n "")

      LitFrac x -> text (show x)

      LitStr x -> ppString x



instance PP Option where
  pp opt =
    case opt of
      OptPrintSuccess b             -> std "print-success" b
      OptExpandDefinitions b        -> std "expand-definitions" b
      OptInteractiveMode b          -> std "interactive-mode" b
      OptProduceProofs b            -> std "produce-proofs" b
      OptProduceUnsatCores b        -> std "produce-unsat-cores" b
      OptProduceModels b            -> std "produce-models" b
      OptProduceAssignments b       -> std "produce-assignments" b
      OptRegularOutputChannel s     -> str "regular-output-channel" s
      OptDiagnosticOutputChannel s  -> str "diagnostic-output-channel" s
      OptRandomSeed n               -> std "random-seed" n
      OptVerbosity n                -> std "verbosity" n
      OptAttr a                     -> pp a

    where mk a b  = char ':' <> text a <+> b
          std a b = mk a (pp b)
          str a b = mk a (ppString b)

instance PP InfoFlag where
  pp info =
    case info of
      InfoAllStatistics -> mk "all-statistics"
      InfoErrorBehavior -> mk "error-behavior"
      InfoName          -> mk "name"
      InfoAuthors       -> mk "authors"
      InfoVersion       -> mk "version"
      InfoStatus        -> mk "status"
      InfoReasonUnknown -> mk "reason-unknown"
      InfoAttr a        -> pp a
    where mk x = char ':' <> text x

instance PP Command where
  pp cmd =
    case cmd of
      CmdSetLogic n     -> std "set-logic" n
      CmdSetOption o    -> std "set-options" o
      CmdSetInfo a      -> std "set-info" a
      CmdDeclareType x n    -> mk "declare-sort" (pp x <+> integer n)
      CmdDefineType x as t  -> fun "define-sort" x as (pp t)
      CmdDeclareFun x ts t  -> fun "declare-fun" x ts (pp t)
      CmdDefineFun x bs t e -> fun "define-fun" x bs (pp t $$ nest 2 (pp e))
      CmdPush n         -> std "push" n
      CmdPop n          -> std "pop" n
      CmdAssert e       -> std "assert" e
      CmdCheckSat       -> one "check-sat"
      CmdGetAssertions  -> one "get-assertions"
      CmdGetValue es    -> mk  "get-value" (parens (fsep (map pp es)))
      CmdGetProof       -> one "get-proof"
      CmdGetUnsatCore   -> one "get-unsat-core"
      CmdGetInfo i      -> std "get-info" i
      CmdGetOption n    -> std "get-option" n
      CmdExit           -> one "exit"
    where mk x d = parens (text x <+> d)
          one x   = mk x empty
          std x a = mk x (pp a)
          fun x y as d = mk x (pp y <+> parens (fsep (map pp as)) <+> d)

instance PP Script where
  pp (Script cs) = vcat (map pp cs)
