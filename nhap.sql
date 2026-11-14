-- Hàm tạm để chuyển dữ liệu từ Google Sheet sang (xoá ngay sau khi dùng).
create or replace function public.nhap_du_lieu(khoa text, ds jsonb) returns jsonb
language plpgsql security definer set search_path = bh, pg_catalog, public as $$
declare kq jsonb := '{}';
begin
  if khoa is distinct from '__KHOA__' then raise exception 'sai khoá'; end if;
  perform pg_advisory_xact_lock(424242);
  truncate bh.cai_dat, bh.nhan_vien, bh.phien, bh.sai_dn, bh.hang_hoa, bh.khach_hang, bh.hoa_don, bh.thu_no, bh.doi_tac,
    bh.phieu_nhap, bh.tra_doi_tac, bh.kiem_kho, bh.nhat_ky, bh.ma_da_lam;

  insert into bh.cai_dat (muc, gia_tri)
    select x->>'muc', coalesce(x->>'giaTri', '') from jsonb_array_elements(ds->'CaiDat') x
    where coalesce(x->>'muc', '') <> '' and x->>'muc' not in ('noTKA', 'noTKAKeToan')
    on conflict (muc) do update set gia_tri = excluded.gia_tri;
  insert into bh.cai_dat (muc, gia_tri) values
    ('ten1','Nông Nghiệp Tây Nguyên'),('ten2','TKA Hòa Nam'),('sdt','0961.414.747'),
    ('diaChi','Thôn 3A, Xã Hòa Bắc, Tỉnh Lâm Đồng'),('loiCamOn',''),('tonToiThieu','5')
    on conflict (muc) do nothing;

  insert into bh.nhan_vien (id, ten_dang_nhap, ho_ten, salt, hash, la_chu, quyen, bi_khoa)
    select bh.so(x->'id'), x->>'tenDangNhap', coalesce(x->>'hoTen', ''), x->>'salt', x->>'hash', (bh.so(x->'laChu') <> 0),
      coalesce((select array_agg(q) from unnest(string_to_array(coalesce(x->>'quyen', ''), ',')) q where q <> ''), '{}'), (bh.so(x->'biKhoa') <> 0)
    from jsonb_array_elements(ds->'NhanVien') x where bh.so(x->'id') > 0;

  insert into bh.hang_hoa (id, ten, don_vi, gia_ban, gia_nhap, ton, ton_toi_thieu, ngung)
    select bh.so(x->'id'), x->>'ten', coalesce(x->>'donVi', ''), bh.so(x->'giaBan'), bh.so(x->'giaNhap'), bh.so(x->'ton'), bh.so(x->'tonToiThieu'), (bh.so(x->'ngung') <> 0)
    from jsonb_array_elements(ds->'HangHoa') x where bh.so(x->'id') > 0;

  insert into bh.khach_hang (id, ten, sdt, dia_chi, han_muc, no, ngung)
    select bh.so(x->'id'), coalesce(x->>'ten', ''), coalesce(x->>'sdt', ''), coalesce(x->>'diaChi', ''), bh.so(x->'hanMuc'), bh.so(x->'no'), (bh.so(x->'ngung') <> 0)
    from jsonb_array_elements(ds->'KhachHang') x where bh.so(x->'id') > 0;

  insert into bh.hoa_don (id, loai, thoi_gian, kh_id, kh_ten, kh_sdt, kh_dia_chi, tong, giam_gia, no_cu, thanh_toan, con_no, nhan_vien, trang_thai, ghi_chu, chi_tiet, items)
    select bh.so(x->'id'), coalesce(nullif(x->>'loai', ''), 'BAN'), bh.so(x->'thoiGian'), bh.so(x->'khId'), coalesce(x->>'khTen', ''), coalesce(x->>'khSdt', ''),
      coalesce(x->>'khDiaChi', ''), bh.so(x->'tong'), bh.so(x->'giamGia'), bh.so(x->'noCu'), bh.so(x->'thanhToan'), bh.so(x->'conNo'),
      coalesce(x->>'nhanVien', ''), coalesce(nullif(x->>'trangThai', ''), 'OK'), coalesce(x->>'ghiChu', ''), coalesce(x->>'chiTiet', ''),
      coalesce(nullif(x->>'items', '')::jsonb, '[]')
    from jsonb_array_elements(ds->'HoaDon') x where bh.so(x->'id') > 0;

  insert into bh.thu_no (id, thoi_gian, kh_id, kh_ten, no_cu, so_tien, con_no, nhan_vien, trang_thai, ghi_chu)
    select bh.so(x->'id'), bh.so(x->'thoiGian'), bh.so(x->'khId'), coalesce(x->>'khTen', ''), bh.so(x->'noCu'), bh.so(x->'soTien'), bh.so(x->'conNo'),
      coalesce(x->>'nhanVien', ''), coalesce(nullif(x->>'trangThai', ''), 'OK'), coalesce(x->>'ghiChu', '')
    from jsonb_array_elements(ds->'ThuNo') x where bh.so(x->'id') > 0;

  insert into bh.doi_tac (id, ten, sdt, dia_chi, no, no_ke_toan, ngung)
    select bh.so(x->'id'), x->>'ten', coalesce(x->>'sdt', ''), coalesce(x->>'diaChi', ''), bh.so(x->'no'),
      case when coalesce(x->>'noKeToan', '') = '' then null else bh.so(x->'noKeToan') end, (bh.so(x->'ngung') <> 0)
    from jsonb_array_elements(ds->'DoiTac') x where bh.so(x->'id') > 0;
  insert into bh.doi_tac (id, ten) select 1, 'TKA' where not exists (select 1 from bh.doi_tac);

  insert into bh.phieu_nhap (id, thoi_gian, tong, nhan_vien, trang_thai, ghi_chu, chi_tiet, items, dt_id, dt_ten)
    select bh.so(x->'id'), bh.so(x->'thoiGian'), bh.so(x->'tong'), coalesce(x->>'nhanVien', ''), coalesce(nullif(x->>'trangThai', ''), 'OK'),
      coalesce(x->>'ghiChu', ''), coalesce(x->>'chiTiet', ''), coalesce(nullif(x->>'items', '')::jsonb, '[]'),
      coalesce(nullif(bh.so(x->'dtId'), 0), 1), coalesce(nullif(x->>'dtTen', ''), 'TKA')
    from jsonb_array_elements(ds->'PhieuNhap') x where bh.so(x->'id') > 0;

  insert into bh.tra_doi_tac (id, thoi_gian, so_tien, nhan_vien, trang_thai, ghi_chu, dt_id, dt_ten)
    select bh.so(x->'id'), bh.so(x->'thoiGian'), bh.so(x->'soTien'), coalesce(x->>'nhanVien', ''), coalesce(nullif(x->>'trangThai', ''), 'OK'),
      coalesce(x->>'ghiChu', ''), coalesce(nullif(bh.so(x->'dtId'), 0), 1), coalesce(nullif(x->>'dtTen', ''), 'TKA')
    from jsonb_array_elements(ds->'TraDoiTac') x where bh.so(x->'id') > 0;

  insert into bh.kiem_kho (thoi_gian, hh_id, ten, ton_so, ton_thuc, chenh_lech, nhan_vien)
    select bh.so(x->'thoiGian'), bh.so(x->'hhId'), coalesce(x->>'ten', ''), bh.so(x->'tonSo'), bh.so(x->'tonThuc'), bh.so(x->'chenhLech'), coalesce(x->>'nhanVien', '')
    from jsonb_array_elements(ds->'KiemKho') x where bh.so(x->'hhId') > 0;

  insert into bh.nhat_ky (thoi_gian, nhan_vien, hanh_dong, chi_tiet)
    select bh.so(x->'thoiGian'), coalesce(x->>'nhanVien', ''), coalesce(x->>'hanhDong', ''), coalesce(x->>'chiTiet', '')
    from jsonb_array_elements(ds->'NhatKy') x where coalesce(x->>'hanhDong', '') <> '';

  perform setval(pg_get_serial_sequence('bh.' || t, 'id'), greatest(coalesce(m, 0), 1), m is not null)
    from (values ('nhan_vien', (select max(id) from bh.nhan_vien)), ('hang_hoa', (select max(id) from bh.hang_hoa)),
      ('khach_hang', (select max(id) from bh.khach_hang)), ('hoa_don', (select max(id) from bh.hoa_don)), ('thu_no', (select max(id) from bh.thu_no)),
      ('doi_tac', (select max(id) from bh.doi_tac)), ('phieu_nhap', (select max(id) from bh.phieu_nhap)), ('tra_doi_tac', (select max(id) from bh.tra_doi_tac))) v(t, m);

  select jsonb_build_object(
    'nhanVien', (select count(*) from bh.nhan_vien), 'hang', (select count(*) from bh.hang_hoa), 'khach', (select count(*) from bh.khach_hang),
    'noKhach', (select coalesce(sum(no), 0) from bh.khach_hang), 'tonKho', (select coalesce(sum(ton), 0) from bh.hang_hoa),
    'hoaDon', (select count(*) from bh.hoa_don), 'thuNo', (select count(*) from bh.thu_no), 'phieuNhap', (select count(*) from bh.phieu_nhap),
    'doiTac', (select count(*) from bh.doi_tac), 'noDoiTac', (select coalesce(sum(no), 0) from bh.doi_tac), 'traDoiTac', (select count(*) from bh.tra_doi_tac),
    'kiemKho', (select count(*) from bh.kiem_kho), 'nhatKy', (select count(*) from bh.nhat_ky)) into kq;
  return kq;
end $$;
revoke all on function public.nhap_du_lieu(text, jsonb) from public;
grant execute on function public.nhap_du_lieu(text, jsonb) to anon;
