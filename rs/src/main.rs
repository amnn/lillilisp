#![feature(alloc)]
extern crate alloc;

use std::mem::size_of;
use gc::{GC, Meta};
use gc::layout::GCLayout;

impl GCLayout for u8 {
    fn get_ref(&self, _ : usize) -> Option<usize> { None }
}

pub mod tokenizer;
pub mod gc;

fn main() {
    unsafe {
        let mut gc = GC::new(1<<7);
        let x = gc.alloc::<u64, u8>(0x11);
        let y = gc.alloc::<u64, u8>(0x22);
        let z = gc.alloc::<u64, u8>(0x33);

        *GC::fetch(x) = 0xDEADBEEFBAADCAFE;
        *GC::fetch(y) = 0xBAADCAFEDEADBEEF;
        *GC::fetch(z) = 0xDEADBEEFDEADBEEF;

        gc.debug();
    }
}
