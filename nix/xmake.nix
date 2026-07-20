{
  pkgs,
  useLLVM ? true,
  ...
}:
let
  isLLVM =
    llvm: llvmDrv: otherDrv:
    if llvm then llvmDrv else otherDrv;
  LLVM_f = pkgs.callPackage ./llvm.nix { };
  Win_f = pkgs.callPackage ./window.nix { };
in
isLLVM useLLVM LLVM_f Win_f
