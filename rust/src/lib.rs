use godot::{init::ExtensionLibrary, prelude::gdextension};

mod perf_monitor;
mod random_table;

struct BenchmarkGdscriptRsExt;

#[gdextension]
unsafe impl ExtensionLibrary for BenchmarkGdscriptRsExt {}
