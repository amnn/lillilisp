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
    Header  { size : u8, off : u8, tag : L,
              ty : PhantomData<T> },
    Forward { off : u8,
              ty : PhantomData<T> },
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
        #[inline(always)]
        fn diff<T, U>(p : *mut T, q : *mut U) -> u8 {
            (q as usize - p as usize) as u8
        }

        let fwd  = pack!(*const Meta<T, L>);
        let data = pack!(T, fwd);
        let meta = pack!(Meta<T, L>);

        loop {
            let hdr = meta.reserve_after(self.free);
            let ptr = data.reserve_after(meta.advance(hdr));
            let end = data.advance(ptr);

            if !self.in_buffer(end) {
                self.make_room();
                continue
            }

            ptr::write(
                hdr,
                Header {
                    size: data.size as u8,
                    tag:  tag,
                    off:  diff(hdr, ptr),
                    ty:   PhantomData
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
        #[inline(always)]
        fn offset<T, U>(p : *const T, off : u8) -> *mut U {
            (p as usize + off as usize) as *mut U
        }

        loop {
            match *m {
                Header  { off, ..} => return offset(m, off),
                Forward { off, ..} => m =   *offset(m, off)
            }
        }
    }

    unsafe fn make_room(&mut self) {
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
