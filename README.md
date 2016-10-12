# reo-web-starter-kit
Boilerplate for sites

<section>
  <p>This kit includes:</p>
  <ul>
    <li><a href="http://coffeescript.org/">CoffeeScript</a></li>
    <li><a href="http://sass-lang.com/">Sass</a></li>
    <li><a href="https://mozilla.github.io/nunjucks/">Nunjucks</a></li>
  </ul>

  <p>And also:</p>
  <ul>
    <li><a href="https://mozilla.github.io/nunjucks/">Bootstrap</a></li>
  </ul>
</section>

<section>
  <p>Gulp tasks:</p>
  <ul>
    <li><code>serve</code> opens site in browser and reloads it automatically on change</li>
    <li><code>serve:dist</code> same but with minification and optimization of built sources</li>
    <li><code>watch</code> builds site automatically on change</li>
    <li><code>clean</code> deletes built sources</li>
    <li><code>build:dist</code> builds site to dist folder</li>
    <li><code>deploy</code> deploy site to <a href="http://surge.sh/">Surge</a></li>
  </ul>
</section>

## Usage
```sh
npm install -g yo gulp-cli generator-reo-web-starter-kit

yo reo-web-starter-kit
gulp serve
```
