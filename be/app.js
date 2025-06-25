import express from 'express'
import cors from 'cors'

import { loginUser, getProduct, getUsers, getUser, addUser, addToKeranjang, updateFavoritProduct, addFavoritProduct, removeFavoritProduct, getUserFavoritProducts, getProductsByKategori, updateUserName, updateUserAddress, updateUserPhone, updateUserGender, updateUserBirthdate, getUserKeranjang, updateJumlahKeranjang, getProductVariants, addProduct, addProductVariant, updateVariantStock, increaseVariantStock, decreaseVariantStock } from './database.js'

const app = express()

// ✅ Tambahkan CORS
app.use(cors())

app.use(express.json())

// login
app.post("/login", async (req, res) => {
  const { email, password } = req.body;

  try {
    const user = await loginUser(email, password);
    res.status(200).json({
      message: "Login berhasil",
      user: user
    });
  } catch (error) {
    res.status(401).json({ error: error.message });
  }
});

// get product
app.get('/produk', async (req, res) => {
  const { id_kategori } = req.query;
  const produk = await getProductsByKategori(id_kategori);
  res.json(produk);
});

app.get("/produk/:id", async (req, res) => {
  const id = req.params.id
  const note = await getProduct(id)
  res.send(note)
})

app.put("/produk/:id", async (req, res) => {
  const id = req.params.id
  const { favorit_product } = req.body
  try {
    const result = await updateFavoritProduct(id, favorit_product)
    if (result.affectedRows === 0) {
      return res.status(404).send({ success: false, message: "Produk tidak ditemukan atau tidak terupdate" })
    }
    res.send({ success: true, message: "Favorit updated" })
  } catch (err) {
    res.status(500).send({ success: false, message: err.message })
  }
})


// Tambah ke favorit
app.post("/favorit", async (req, res) => {
  const { id_user, id_product } = req.body;
  try {
    await addFavoritProduct(id_user, id_product);
    res.json({ success: true, message: "Produk ditambahkan ke favorit" });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// Tambahkan endpoint untuk ambil varian produk
app.get('/produk/:id/varian', async (req, res) => {
  const id = req.params.id;
  try {
    const variants = await getProductVariants(id);
    res.json(variants);
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// Hapus dari favorit
app.delete("/favorit", async (req, res) => {
  const { id_user, id_product } = req.body;
  try {
    await removeFavoritProduct(id_user, id_product);
    res.json({ success: true, message: "Produk dihapus dari favorit" });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// Ambil produk favorit milik user
app.get("/favorit/:id_user", async (req, res) => {
  const id_user = req.params.id_user;
  try {
    const result = await getUserFavoritProducts(id_user);
    res.json(result);
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// get users
app.get("/users", async (req, res) => {
  const notes = await getUsers()
  res.send(notes)
})

app.get("/users/:id", async (req, res) => {
  const id = req.params.id
  const note = await getUser(id)
  res.send(note)
})

app.post("/users", async (req, res) => {
  try {
    const newUser = await addUser(req.body);
    res.status(201).json({
      message: "User berhasil ditambahkan",
      user: newUser
    });
  } catch (error) {
    console.error('Error adding user:', error);
    res.status(500).json({ error: "Gagal menambahkan user" });
  }
});

// PATCH user
app.patch("/users/:id", async (req, res) => {
  const id = req.params.id;
  const { nama_user, alamat_user, nohp_user, jeniskelamin_user, tgllahir_user } = req.body;
  try {
    let result;
    if (nama_user !== undefined) {
      result = await updateUserName(id, nama_user);
    }
    if (alamat_user !== undefined) {
      result = await updateUserAddress(id, alamat_user);
    }
    if (nohp_user !== undefined) {
      result = await updateUserPhone(id, nohp_user);
    }
    if (jeniskelamin_user !== undefined) {
      result = await updateUserGender(id, jeniskelamin_user);
    }
    if (tgllahir_user !== undefined) {
      result = await updateUserBirthdate(id, tgllahir_user);
    }
    if (!result || result.affectedRows === 0) {
      return res.status(404).send({ success: false, message: "User tidak ditemukan atau tidak terupdate" });
    }
    res.send({ success: true, message: "User updated" });
  } catch (err) {
    res.status(500).send({ success: false, message: err.message });
  }
});

// get keranjang
app.get("/keranjang/:id_user", async (req, res) => {
  const id_user = req.params.id_user;
  try {
    const result = await getUserKeranjang(id_user);
    res.json(result);
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

app.post("/keranjang", async (req, res) => {
  try {
    const item = await addToKeranjang(req.body);
    res.status(201).json({
      message: "Item berhasil ditambahkan ke keranjang",
      data: item
    });
  } catch (error) {
    console.error("Error:", error);
    res.status(500).json({ error: "Gagal menambahkan ke keranjang" });
  }
});

// PATCH jumlah produk di keranjang
app.patch("/keranjang", async (req, res) => {
  const { id_user, id_product, id_varian, jumlah } = req.body;
  try {
    const result = await updateJumlahKeranjang(id_user, id_product, id_varian, jumlah);

    if (result.affectedRows === 0) {
      return res.status(404).json({ success: false, message: "Produk tidak ditemukan di keranjang" });
    }

    if (result.deleted) {
      res.json({ success: true, message: "Produk dihapus dari keranjang karena jumlah 0" });
    } else {
      res.json({ success: true, message: "Jumlah produk di keranjang diperbarui" });
    }

  } catch (error) {
    console.error("Error:", error);
    res.status(500).json({ success: false, message: "Gagal memperbarui keranjang" });
  }
});

//Web admin
app.post("/produk", async (req, res) => {
  try {
    const { nama_product, harga_product, favorit_product, nohp_seller, id_kategori, variants } = req.body;

    const id_product = await addProduct({ nama_product, harga_product, favorit_product, nohp_seller, id_kategori });

    // Tambahkan semua varian
    for (const variant of variants) {
      await addProductVariant({ id_product, ...variant });
    }

    res.status(201).json({ success: true, id_product });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: err.message });
  }
});
// Tambah stok varian produk
app.patch('/varian/:id/stok/tambah', async (req, res) => {
  const id = req.params.id;
  const { amount } = req.body;
  if (typeof amount !== 'number' || amount <= 0) {
    return res.status(400).json({ success: false, message: 'Jumlah penambahan stok harus berupa angka positif' });
  }
  try {
    const result = await increaseVariantStock(id, amount);
    if (result.affectedRows === 0) {
      return res.status(404).json({ success: false, message: 'Varian tidak ditemukan' });
    }
    res.json({ success: true, message: 'Stok varian berhasil ditambah' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// Kurangi stok varian produk
app.patch('/varian/:id/stok/kurang', async (req, res) => {
  const id = req.params.id;
  const { amount } = req.body;
  if (typeof amount !== 'number' || amount <= 0) {
    return res.status(400).json({ success: false, message: 'Jumlah pengurangan stok harus berupa angka positif' });
  }
  try {
    const result = await decreaseVariantStock(id, amount);
    if (result.affectedRows === 0) {
      return res.status(404).json({ success: false, message: 'Varian tidak ditemukan' });
    }
    res.json({ success: true, message: 'Stok varian berhasil dikurangi' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// Update stok varian produk secara langsung
app.patch('/varian/:id/stok', async (req, res) => {
  const id = req.params.id;
  const { stok } = req.body;
  if (typeof stok !== 'number' || stok < 0) {
    return res.status(400).json({ success: false, message: 'Stok harus berupa angka >= 0' });
  }
  try {
    const result = await updateVariantStock(id, stok);
    if (result.affectedRows === 0) {
      return res.status(404).json({ success: false, message: 'Varian tidak ditemukan' });
    }
    res.json({ success: true, message: 'Stok varian berhasil diupdate' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

app.use((err, req, res, next) => {
  console.error(err.stack)
  res.status(500).send('Something broke 💩')
})

app.listen(8080, '0.0.0.0', () => {
  console.log('Server is running on port 8080')
})