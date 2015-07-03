use std::mem;
use std::marker::PhantomData;

macro_rules! size  { ($t : ty) => { mem::size_of::<$t>() } }
macro_rules! align { ($t : ty) => { mem::align_of::<$t>() } }
macro_rules! pack  { ($t : ty) => { layout::Packing::<$t>::new() }}

#[derive(Copy, Clone, Debug, PartialEq)]
pub struct Packing<T> {
    pub size : usize,
    pub align : usize,
    ty : PhantomData<T>
}

impl<T> Packing<T> {
    pub fn new() -> Self {
        Packing {
            size:  size!(T),
            align: align!(T),
            ty:    PhantomData
        }
    }
}

/// Gives the smallest multiple of `p2` greater than or equal to `x`.
/// This function is used when calculating alignments.
///
/// # Safety
///
/// `p2` is assumed to be a power of 2.
#[inline(always)]
unsafe fn ceil_p2(x : usize, p2 : usize) -> usize {
    let before = x & !(p2 - 1);

    if before == x { before }
    else           { before + p2 }
}

#[inline(always)]
unsafe fn align_fwd<U, T>(p : *mut U, align : usize) -> *mut T {
    ceil_p2(p as usize, align) as *mut T
}

impl<T> Packing<T> {
    #[inline]
    pub unsafe fn reserve_after<U>(&self, p : *mut U) -> *mut T {
        align_fwd(p, self.align)
    }

    #[inline]
    pub unsafe fn advance<U>(&self, p : *mut U) -> *mut u8 {
        (p as *mut u8).offset(self.size as isize)
    }

    #[inline]
    pub unsafe fn footprint<U>(&self, p : *mut U) -> usize {
        self.advance(self.reserve_after(p)) as usize - p as usize
    }
}

pub struct Refs<'a, T : GCLayout + 'a> {
    tag : &'a T,
    pos : usize
}

impl<'a, T : GCLayout> Iterator for Refs<'a, T> {
    type Item = usize;

    fn next(&mut self) -> Option<usize> {
        self.tag
            .get_ref(self.pos)
            .map(|r| { self.pos += 1; r })
    }
}

pub trait GCLayout : Sized {
    fn get_ref(&self, usize) -> Option<usize>;
    fn refs(&self) -> Refs<Self> {
        Refs { tag: self, pos: 0 }
    }
}
