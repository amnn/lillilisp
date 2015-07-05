use std::cmp::max;
use std::mem;

macro_rules! size  { ($t : ty) => { mem::size_of::<$t>() as u8 } }
macro_rules! align { ($t : ty) => { mem::align_of::<$t>() as u8 } }

macro_rules! pack {
    ($t : ty)               => { layout::Packing::new::<$t>() };
    ($t : ty , $oth : expr) => { layout::Packing::at_least::<$t>($oth) }
}

#[derive(Clone, Copy, Debug, PartialEq)]
pub struct Packing {
    pub size  : u8,
    pub align : u8,
}

impl Packing {
    pub fn new<T>() -> Self {
        Packing::raw(size!(T), align!(T))
    }

    pub fn at_least<T>(other : Packing) -> Self {
        Packing::raw(max(size!(T),  other.size),
                     max(align!(T), other.align))
    }

    pub fn raw(size : u8, align : u8) -> Self {
        Packing { size: size, align: align, }
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
unsafe fn align_fwd<U, T>(p : *mut U, align : u8) -> *mut T {
    ceil_p2(p as usize, align as usize) as *mut T
}

impl Packing {
    #[inline]
    pub unsafe fn align_after<T, U>(&self, p : *mut U) -> *mut T {
        align_fwd(p, self.align)
    }

    #[inline]
    pub unsafe fn advance<U>(&self, p : *mut U) -> *mut u8 {
        (p as *mut u8).offset(self.size as isize)
    }

    #[inline]
    pub unsafe fn footprint<U>(&self, p : *mut U) -> usize {
        self.advance::<u8>(self.align_after(p)) as usize - p as usize
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

pub trait GCLayout : Sized + Copy + Clone {
    fn get_ref(&self, usize) -> Option<usize>;
    fn refs(&self) -> Refs<Self> {
        Refs { tag: self, pos: 0 }
    }
}
