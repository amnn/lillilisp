#![feature(alloc)]
extern crate alloc;

use gc::GC;
use gc::layout::GCLayout;

impl GCLayout for u8 {
    fn get_ref(&self, _ : usize) -> Option<usize> { None }
}

pub mod tokenizer;
pub mod gc;

fn main() {
    unsafe {
        let mut gc = GC::<u8>::new(1<<7);
        let x = gc.alloc::<u64>(0x11);
        let y = gc.alloc::<u64>(0x22);
        let z = gc.alloc::<u64>(0x33);

        *gc.fetch::<u64>(x) = 0xDEADBEEFBAADCAFE;
        *gc.fetch::<u64>(y) = 0xBAADCAFEDEADBEEF;
        *gc.fetch::<u64>(z) = 0xDEADBEEFDEADBEEF;

        gc.debug();
    }
}
