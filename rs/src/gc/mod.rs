#[macro_use]
pub mod layout;

use alloc::heap;
use std::mem;
use std::ptr;
use std::slice;

use self::layout::{GCLayout, Packing};
use self::Meta::*;

pub enum Meta<L : GCLayout> {
    Header  { off  : u8, size : u8,
              algn : u8, tag  : L },
    Forward { off : u8, },
}

pub struct GC<'a, L : GCLayout> {
    pub data : &'a mut [u8],
    free : *mut u8,
    root : Vec<*const Meta<L>>
}

unsafe fn halloc(size : usize) -> *mut u8 {
    let buf = heap::allocate(size, mem::align_of::<u8>());
    if buf.is_null() { panic!("Out of memory!"); }
    buf
}

#[inline(always)]
fn diff<T, U>(p : *mut T, q : *mut U) -> u8 {
    (q as usize - p as usize) as u8
}

#[inline(always)]
fn offset<T, U>(p : *const T, off : u8) -> *mut U {
    (p as usize + off as usize) as *mut U
}

#[inline(always)]
unsafe fn end<'a>(data : &'a mut [u8]) -> *mut u8 {
    data.as_mut_ptr()
        .offset(data.len() as isize)
}

#[inline(always)]
unsafe fn in_buffer<'a, T>(data : &'a mut [u8], ptr : *mut T) -> bool {
    (ptr as usize) < (end(data) as usize)
}

#[inline(always)]
unsafe fn alloc_after<'a, L : GCLayout>
    (free : *mut u8,
     buf  : &'a mut [u8],
     tag  : L,
     data : &Packing)
     -> Option<(*mut u8, *const Meta<L>)>
{
    let meta = pack!(Meta<L>);

    let hdr = meta.align_after(free);
    let ptr = data.align_after::<u8, _>(meta.advance(hdr));
    let end = data.advance(ptr);

    if !in_buffer(buf, end) {
        None
    } else {
        ptr::write(
            hdr,
            Header {
                size: data.size,
                algn: data.align,
                tag:  tag,
                off:  diff(hdr, ptr),
            });
        Some((end, hdr))
    }
}

#[inline]
unsafe fn transfer<'a, L : GCLayout>
    (from     : *const Meta<L>,
     to       : *mut u8,
     to_space : &'a mut [u8])
    -> Option<(*mut u8, *const Meta<L>)>
{
    if let Header { size, algn, tag, off, ..} = *from {
        alloc_after::<L>(
            to, to_space, tag,
            &Packing::raw(size, algn))
            .map(|(end, hdr)| {
                if let Header { off: new_off, ..} = *hdr {
                    ptr::copy::<u8>(
                        offset(from, off),
                        offset(hdr, new_off),
                        size as usize)
                } else { unreachable!() }

                (end, hdr)
            })
    } else { unreachable!(); }
}

impl<'a, L : GCLayout> GC<'a, L> {
    pub unsafe fn new(size : usize) -> Self {
        let buf = halloc(size);
        GC {
            data: slice::from_raw_parts_mut(buf, size),
            free: buf, root: vec![]
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
    pub unsafe fn alloc<T : Sized>
        (&mut self, tag : L)
         -> *const Meta<L>
    {
        let fwd  = pack!(*const Meta<L>);
        let pack = pack!(T, fwd);

        let mut attempts = 0;
        loop {
            let opt_end =
                alloc_after(
                    self.free,
                    self.data,
                    tag, &pack);

            if let Some((end, hdr)) = opt_end {
                self.free = end;
                return hdr
            } else if attempts == 0 {
                self.collect();
                attempts += 1;
            } else {
                self.expand();
            }
        }
    }

    /// Convert a pointer to GC Metadata to a pointer to the data it is the
    /// metadata of.
    pub unsafe fn fetch<T>
        (&self, mut m : *const Meta<L>)
         -> *mut T
    {
        loop {
            match *m {
                Header  { off, ..} => return        offset(m, off),
                Forward { off, ..} => m = ptr::read(offset(m, off))
            }
        }
    }

    unsafe fn collect(&mut self) {
        let size     = self.data.len();
        let free     = halloc(size);
        let to_space = slice::from_raw_parts_mut(free, size);
        self.collect_in(free, to_space)
    }

    unsafe fn expand(&mut self) {
        let size     = 2 * self.data.len();
        let free     = halloc(size);
        let to_space = slice::from_raw_parts_mut(free, size);
        self.collect_in(free, to_space)
    }

    unsafe fn collect_in
        (&mut self,
         mut free : *mut u8,
         to_space : &'a mut [u8])
    {
        let mut explored = free;
        for r in &mut self.root {
            let (end, hdr) =
                transfer(*r, free, to_space)
                .expect("GC Root Copy failed!");

            *r   = hdr;
            free = end;
        }

        while explored < free {
            unimplemented!();
        }
    }

    pub fn debug(&self) {
        println!("buff start: {:?}", self.data.as_ptr());
        for ch in self.data.chunks(8) {
            for c in ch { print!("{:02X} ", c) }
            println!("")
        }
    }
}
