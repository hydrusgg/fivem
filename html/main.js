Vue.config.productionTip = false
Vue.config.devtools = false

const remote = new Proxy({}, {
  get(cache, key) {
    if (!cache[key]) {
      cache[key] = (...args) => app.callback('remote', key, ...args).then(([ok, res]) => (
        ok ? res : Promise.reject(res)
      ))
    }
    return cache[key]
  }
})

const app = new Vue({
  el: '#root',
  data: {
    visible: !!location.port,
    credits: [],
    checkout: false,
    category: null,
    popup: {},
    error: '',
    form: {},
    lang: {},
  },
  computed: {
    current() {
      return this.credits[this.checkout]
    },
    products() {
      return this.credits.filter(c => c.category === this.category)
    },
    categories() {
      return this.credits.map(c => c.category).filter((o, i, a) => a.indexOf(o) == i)
    },
  },
  watch: {
    categories(v) {
      this.category = v[0]
    }
  },
  methods: {
    callback(name, ...args) {
      const script = window.GetParentResourceName?.()
      return fetch(`http://${script}/${name}`, {
        method: 'POST',
        body: JSON.stringify(args)
      }).then(res => res.json())
    },
    remote(name, ...args) {
      return this.callback('remote', name, ...args)
    },
    open_url(url) {
      console.log('Opening '+url)
      window.invokeNative('openUrl', url)
    },
    set_current(index) {
      this.error = ''
      this.form = {}
      this.checkout = index
    },
    set_popup(name, image) {
      if (!name) {
        this.popup = {}
      } else {
        this.popup = { name, image, visible:true }
      }
    },
    set_visible(b) {
      this.visible = b
    },
    set_credits(credits) {
      this.credits = credits
    },
    set_category(category) {
      this.category = category
      this.checkout = false
      this.form = {}
    },
    redeem() {
      const credit = this.current
      remote.redeem(this.checkout+1, this.form).then(() => {
        this.close()
        this.set_popup(credit.name, credit.image)
        setTimeout(() => {
          this.set_popup()
        }, 3000)
      }).catch(err => {
        this.error = err.substring(err.lastIndexOf(':')+1).trim()
      })
    },
    close() {
      this.visible = false
      this.checkout = false
      this.selected = false
      this.callback('close')
    },
    _(name, args) {
      return this.lang[name]?.replace?.(/:\w+/g, (name) => {
        return args[name.substring(1)]
      })
    },
  },
  created() {
    document.body.style.display = 'block'

    window.onmessage = ({ data }) => {
      if (Array.isArray(data)) {
        const method = data.shift()
        this[method]?.(...data)
      }
    }

    window.onkeydown = ({ key }) => {
      if (key === 'Escape') {
        this.close()
      }
    }

    this.callback('get_lang').then(lang => this.lang = lang)
  }
})

if (location.hostname === '127.0.0.1') {
  app.credits = [
    {
      name: 'Casa Luxury',
      image: 'https://external-content.duckduckgo.com/iu/?u=http%3A%2F%2Fwww.thestar.com%2Fcontent%2Fdam%2Fthestar%2Flife%2Fhomes%2F2011%2F05%2F19%2Fgta_luxury_housing_includes_8m_oakville_home%2Fluxury1.jpeg&f=1&nofb=1',
      credits: 1,
      category: 'Casas',
      label: 'Escolha uma casa',
      form: [
        {
          label: 'Escolha uma casa',
          options: [
            { label: 'LX50', value: 'LX50' }
          ]
        }
      ],
      consume: 1
    },
    {
      name: 'Número de Telefone',
      image: 'https://external-content.duckduckgo.com/iu/?u=http%3A%2F%2Fwww.thestar.com%2Fcontent%2Fdam%2Fthestar%2Flife%2Fhomes%2F2011%2F05%2F19%2Fgta_luxury_housing_includes_8m_oakville_home%2Fluxury1.jpeg&f=1&nofb=1',
      credits: 1,
      label: 'Insira seu novo número',
      placeholder: '000-000',
      consume: 1
    },
    {
      name: 'Casa Luxury',
      category: 'Casas',
      image: 'https://external-content.duckduckgo.com/iu/?u=http%3A%2F%2Fwww.thestar.com%2Fcontent%2Fdam%2Fthestar%2Flife%2Fhomes%2F2011%2F05%2F19%2Fgta_luxury_housing_includes_8m_oakville_home%2Fluxury1.jpeg&f=1&nofb=1',
      credits: 0,
      consume: 1
    },
    {
      name: 'Casa Luxury',
      category: 'Casas',
      image: 'https://external-content.duckduckgo.com/iu/?u=http%3A%2F%2Fwww.thestar.com%2Fcontent%2Fdam%2Fthestar%2Flife%2Fhomes%2F2011%2F05%2F19%2Fgta_luxury_housing_includes_8m_oakville_home%2Fluxury1.jpeg&f=1&nofb=1',
      credits: 0,
      consume: 1
    },
    {
      name: 'Casa Luxury',
      category: 'Casas',
      image: 'https://external-content.duckduckgo.com/iu/?u=http%3A%2F%2Fwww.thestar.com%2Fcontent%2Fdam%2Fthestar%2Flife%2Fhomes%2F2011%2F05%2F19%2Fgta_luxury_housing_includes_8m_oakville_home%2Fluxury1.jpeg&f=1&nofb=1',
      credits: 0,
      consume: 1
    },
    {
      name: 'Casa Luxury',
      category: 'Casas',
      image: 'https://external-content.duckduckgo.com/iu/?u=http%3A%2F%2Fwww.thestar.com%2Fcontent%2Fdam%2Fthestar%2Flife%2Fhomes%2F2011%2F05%2F19%2Fgta_luxury_housing_includes_8m_oakville_home%2Fluxury1.jpeg&f=1&nofb=1',
      credits: 0,
      consume: 1
    }
  ]
  app.lang = {
    'redeem.one': 'Resgatar um',
    'redeem.many': 'Resgatar vários',
    'redeem': 'Resgatar',
    'confirm': 'Confirmar',
    'credits.insufficient': 'Créditos insuficientes'
  }
}