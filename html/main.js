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
    visible: false,
    credits: [],
    checkout: false,
    error: '',
    form: {},
    lang: {},
  },
  computed: {
    current() {
      return this.credits[this.checkout]
    }
  },
  methods: {
    callback(name, ...args) {
      return fetch(`http://${GetParentResourceName()}/${name}`, {
        method: 'POST',
        body: JSON.stringify(args)
      }).then(res => res.json())
    },
    remote(name, ...args) {
      return this.callback('remote', name, ...args)
    },
    set_current(index) {
      this.error = ''
      this.form = {}
      this.checkout = index
    },
    set_visible(b) {
      this.visible = b
    },
    set_credits(credits) {
      this.credits = credits
    },
    redeem() {
      remote.redeem(this.checkout+1, this.form).then(() => {
        this.set_current(false)
      }).catch(err => this.error = err)
    },
    _(name, args) {
      return this.lang[name].replace(/:\w+/g, (name) => {
        return args[name.substring(1)]
      })
    }
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
        this.visible = false
        this.checkout = false
        this.selected = false
        this.callback('close')
      }
    }

    this.callback('get_lang').then(lang => this.lang = lang)
  }
})

if (location.hostname === '127.0.0.1') {
  app.visible = true
  app.credits = [
    {
      name: 'Casa Luxury',
      image: 'https://external-content.duckduckgo.com/iu/?u=http%3A%2F%2Fwww.thestar.com%2Fcontent%2Fdam%2Fthestar%2Flife%2Fhomes%2F2011%2F05%2F19%2Fgta_luxury_housing_includes_8m_oakville_home%2Fluxury1.jpeg&f=1&nofb=1',
      credits: 1,
      label: 'Escolha uma casa',
      options: ['LX01', 'LX02'],
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
      image: 'https://external-content.duckduckgo.com/iu/?u=http%3A%2F%2Fwww.thestar.com%2Fcontent%2Fdam%2Fthestar%2Flife%2Fhomes%2F2011%2F05%2F19%2Fgta_luxury_housing_includes_8m_oakville_home%2Fluxury1.jpeg&f=1&nofb=1',
      credits: 0,
      consume: 1
    },
    {
      name: 'Casa Luxury',
      image: 'https://external-content.duckduckgo.com/iu/?u=http%3A%2F%2Fwww.thestar.com%2Fcontent%2Fdam%2Fthestar%2Flife%2Fhomes%2F2011%2F05%2F19%2Fgta_luxury_housing_includes_8m_oakville_home%2Fluxury1.jpeg&f=1&nofb=1',
      credits: 0,
      consume: 1
    },
    {
      name: 'Casa Luxury',
      image: 'https://external-content.duckduckgo.com/iu/?u=http%3A%2F%2Fwww.thestar.com%2Fcontent%2Fdam%2Fthestar%2Flife%2Fhomes%2F2011%2F05%2F19%2Fgta_luxury_housing_includes_8m_oakville_home%2Fluxury1.jpeg&f=1&nofb=1',
      credits: 0,
      consume: 1
    },
    {
      name: 'Casa Luxury',
      image: 'https://external-content.duckduckgo.com/iu/?u=http%3A%2F%2Fwww.thestar.com%2Fcontent%2Fdam%2Fthestar%2Flife%2Fhomes%2F2011%2F05%2F19%2Fgta_luxury_housing_includes_8m_oakville_home%2Fluxury1.jpeg&f=1&nofb=1',
      credits: 0,
      consume: 1
    }
  ]
}