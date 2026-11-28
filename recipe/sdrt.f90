! Write an int32 SDS + attribute with the HDF4 Fortran SD API, read both back, compare.
program sdrt
  implicit none
  include "hdf.f90"
  integer :: sfstart, sfcreate, sfwdata, sfsnatt, sfendacc, sfend, sfselect, sfrdata, sffattr, sfrnatt
  external :: sfstart, sfcreate, sfwdata, sfsnatt, sfendacc, sfend, sfselect, sfrdata, sffattr, sfrnatt
  integer :: sd, ds, st, i, ia
  integer :: dims(1), start(1), edges(1), stride(1), v(10), r(10), att(3), ratt(3)
  do i = 1, 10; v(i) = 100000*i - 7; end do
  att = (/ 2147483647, -2147483647, 42 /)
  sd = sfstart("sdrt.hdf", DFACC_CREATE); if (sd == -1) stop 1
  dims(1) = 10
  ds = sfcreate(sd, "ds", DFNT_INT32, 1, dims); if (ds == -1) stop 2
  st = sfsnatt(ds, "a", DFNT_INT32, 3, att); if (st == -1) stop 3
  start = 0; stride = 1; edges = 10
  st = sfwdata(ds, start, stride, edges, v); if (st == -1) stop 4
  st = sfendacc(ds); st = sfend(sd)
  sd = sfstart("sdrt.hdf", DFACC_READ); if (sd == -1) stop 5
  ds = sfselect(sd, 0); if (ds == -1) stop 6
  st = sfrdata(ds, start, stride, edges, r); if (st == -1) stop 7
  ia = sffattr(ds, "a"); st = sfrnatt(ds, ia, ratt); if (st == -1) stop 8
  st = sfendacc(ds); st = sfend(sd)
  if (any(r /= v)) stop 9
  if (any(ratt /= att)) stop 10
  print *, "HDF4 Fortran SD round-trip OK"
end program sdrt
