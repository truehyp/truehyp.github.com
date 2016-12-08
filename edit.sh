#/bin/bash
sed -i 's/href=\".*\"\(>.*HOME\)/href=\"http:\/\/wiki.houye.xyz\"\1/g' *.html
sed -i 's#http://orgmode.org/mathjax/MathJax.js#js/MathJax.js#g' *.html

