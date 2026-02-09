## Self Reflection
### Bagaimana prinsip SRP membantu saat menambah fitur History Logger?

Karena saya sudah terbiasa menerapkan SRP, penambahan fitur History Logger menjadi cukup straightforward. Setiap class sudah memiliki tanggung jawab yang jelas, jadi saya tinggal membuat class baru untuk History Logger tanpa perlu mengubah class yang sudah ada.

Yang saya sukai dari penerapan SRP ini adalah:
- Saya bisa menambahkan fitur baru tanpa takut merusak fitur yang sudah berjalan
- Class History Logger bisa di-test secara terpisah
- Kode tetap rapi dan mudah di-maintain ke depannya
