#[macro_use]
pub mod layout;

use alloc::heap;
use std::marker::PhantomData;
use std::mem;
use std::ptr;
use std::slice;

use self::layout::GCLayout;
use self::Meta::*;

pub enum Meta<T, L : GCLayout> {
    Header  { tag : L, size : u8,
              ptr : *mut T },
    Forward { fwd : *const Meta<T, L> },
}

pub struct GC<'a> {
    pub data : &'a mut [u8],
    free : *mut u8
}

unsafe fn halloc(size : usize) -> *mut u8 {
    let buf = heap::allocate(size, align!(u8));
    if buf.is_null() { panic!("Out of memory!"); }
    buf
}

impl<'a> GC<'a> {
    pub unsafe fn new(size : usize) -> Self {
        let buf = halloc(size);
        GC {
            data: slice::from_raw_parts_mut(buf, size),
            free: buf
        }
    }

    /// Allocates space on the heap for a value of type `T` as well as the GC
    /// metadata.
    ///
    /// ```
    /// +------+-----+----------+
    /// | ptr  | tag | data...  |
    /// +------+-----+----------+
    /// ```
    ///
    /// GC Metadata is composed of a `ptr` and `tag` above. The tag is used to
    /// describe the memory layout of `data` to the GC.
    ///
    /// # Safety
    ///
    /// The memory allocated is not initialised, merely reserved. The initial
    /// contents must be written by the caller.
    pub unsafe fn alloc<T : Sized, L : GCLayout>
        (&mut self, tag : L)
         -> *const Meta<T, L>
    {
        let data = pack!(T);
        let meta = pack!(Meta<T, L>);

        loop {
            let hdr = meta.reserve_after(self.free);
            let ptr = data.reserve_after(meta.advance(hdr));
            let end = data.advance(ptr);

            if !self.in_buffer(end) {
                self.make_room(end as usize);
                continue
            }

            ptr::write(
                hdr,
                Header {
                    size: data.size as u8,
                    tag:  tag,
                    ptr:  &mut *ptr,
                });

            self.free = end;
            return hdr
        }
    }

    /// Convert a pointer to GC Metadata to a pointer to the data it is the
    /// metadata of.
    pub unsafe fn fetch<T, L : GCLayout>
        (mut m : *const Meta<T, L>)
         -> *mut T
    {
        loop {
            match *m {
                Header  { ptr, ..} => return ptr,
                Forward { fwd }    => m = fwd
            }
        }
    }

    unsafe fn make_room(&mut self, footprint : usize) {
        unimplemented!()
    }

    #[inline(always)]
    unsafe fn in_buffer<T>(&mut self, ptr : *mut T) -> bool {
        (ptr as usize) < (self.data_end() as usize)
    }

    #[inline(always)]
    unsafe fn data_end(&mut self) -> *mut u8 {
        self.data
            .as_mut_ptr()
            .offset(self.data.len() as isize)
    }

    pub fn debug(&self) {
        println!("buff start: {:?}", self.data.as_ptr());
        for ch in self.data.chunks(8) {
            for c in ch { print!("{:02X} ", c) }
            println!("")
        }
    }
}
