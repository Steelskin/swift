// RUN: %target-swift-frontend -primary-file %s -emit-ir -swift-version 6 -enable-experimental-feature IsolatedConformances | %FileCheck %s -DINT=i%target-ptrsize

// REQUIRES: PTRSIZE=64
// REQUIRES: concurrency
// REQUIRES: swift_feature_IsolatedConformances
// UNSUPPORTED: CPU=arm64e

protocol P {
  func f()
}

// CHECK-LABEL: @"$s20isolated_conformance1XVyxGAA1PAAMc" =
// CHECK-SAME: ptr @"$s20isolated_conformance1PMp"
// CHECK-SAME: ptr @"$s20isolated_conformance1XVMn"
// CHECK-SAME: ptr @"$s20isolated_conformance1XVyxGAA1PAAWP
// CHECK-SAME: i32 524288
// CHECK-SAME: ScM
// CHECK-SAME: $sScMs11GlobalActorsMc"
@MainActor
struct X<T>: isolated P {
  func f() { }
}
