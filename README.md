visual block insert.

```sh
cat /usr/include/stdbit.h | nvim --clean --cmd "se rtp^=$(realpath "$PWD")" --cmd 'se ve=block ft=c'
```

https://github.com/user-attachments/assets/e4aa8e25-5268-4051-8186-5b5dc9cc383b
