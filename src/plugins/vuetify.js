import Vue from "vue";
import Vuetify from "vuetify/lib/framework";

Vue.use(Vuetify);

export default new Vuetify({
  theme: {
    dark: false,
    themes: {
      dark: {
        primary: "#29b5e7",
      },
      light: {
        primary: "#29b5e7",
      },
    },
  },
});
