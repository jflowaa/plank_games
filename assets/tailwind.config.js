// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration
module.exports = {
  darkMode: 'media',
  content: [
    './js/**/*.js',
    '../lib/*_web.ex',
    '../lib/*_web/**/*.*ex'
  ],
  theme: {
    extend: {},
    container: {
      center: true,
    },
  },
  plugins: [
    require('@tailwindcss/forms')
  ]
}
