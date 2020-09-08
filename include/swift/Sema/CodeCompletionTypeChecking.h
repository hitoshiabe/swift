//
// Copyright (c) 2014 - 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//
//
/// \file
/// Provides TypeCheckCompletionCallback implementations for the various kinds
/// of code completion. These extract and persist information needed to compute
/// completion results from the solutions formed during expression typechecking.
//
//===----------------------------------------------------------------------===//

#ifndef SWIFT_SEMA_CODECOMPLETIONTYPECHECKING_H
#define SWIFT_SEMA_CODECOMPLETIONTYPECHECKING_H

namespace swift {
  class Decl;
  class DeclContext;
  class Type;
  class ValueDecl;
  class CodeCompletionExpr;

  namespace constraints {
    class Solution;
  }

  class TypeCheckCompletionCallback {
  public:
    /// Called for each solution produced while  type-checking an expression
    /// containing a code completion expression.
    virtual void sawSolution(const constraints::Solution &solution) = 0;
    virtual ~TypeCheckCompletionCallback() {}
  };


  /// Used to collect and store information needed to perform member completion
  /// (\c CompletionKind::DotExpr ) from the solutions formed during expression
  /// type-checking.
  class DotExprTypeCheckCompletionCallback: public TypeCheckCompletionCallback {
  public:
    struct Result {
      Type BaseTy;
      ValueDecl* BaseDecl;
      SmallVector<Type, 4> ExpectedTypes;
      bool ExpectsNonVoid;
      bool BaseIsStaticMetaType;
      bool IsSingleExpressionBody;
    };

  private:
    DeclContext *DC;
    CodeCompletionExpr *CompletionExpr;
    SmallVector<Result, 4> Results;
    llvm::DenseMap<std::pair<Type, Decl*>, size_t> BaseToSolutionIdx;
    bool GotCallback = false;

  public:
    DotExprTypeCheckCompletionCallback(DeclContext *DC,
                                       CodeCompletionExpr *CompletionExpr)
      : DC(DC), CompletionExpr(CompletionExpr) {}

    /// Get the results collected from any sawSolutions() callbacks recevied so
    /// far.
    ArrayRef<Result> getResults() const { return Results; }

    /// True if at least one solution was passed via the \c sawSolution
    /// callback.
    bool gotCallback() const { return GotCallback; }

    /// Typecheck the code completion expression in isolation, calling
    /// \c sawSolution for each solution formed.
    void fallbackTypeCheck();

    void sawSolution(const constraints::Solution &solution) override;
  };
}

#endif
