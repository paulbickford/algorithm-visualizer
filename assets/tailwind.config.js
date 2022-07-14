// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration
module.exports = {
  content: ['./js/**/*.js', '../lib/*_web.ex', '../lib/*_web/**/*.*ex'],
  safelist: [
    {
      pattern: /top-(0|12|24|36|48|60)/,
      variants: ['md'],
    },
    {
      pattern: /left-(0|16|32|48|64|80|96)/,
      variants: ['md'],
    },
    {
      pattern: /translate-x-(16|32|48|64|80|96)/,
      variants: ['md'],
    },
    {
      pattern: /-translate-x-(16|32|48|64|80|96)/,
      variants: ['md'],
    },
    {
      pattern: /translate-y-(12|24|36|48|60)/,
      variants: ['md'],
    },
    {
      pattern: /-translate-y-(12|24|36|48|60)/,
      variants: ['md'],
    },
  ],
  theme: {
    extend: {},
  },
  plugins: [require('@tailwindcss/forms')],
};
