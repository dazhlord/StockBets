<template>
  <v-app
    id="main"
    :style="{ background: $vuetify.theme.themes[theme].background }"
  >
    <v-app-bar app outlined color="primary">
      <div class="d-flex align-center"></div>
    </v-app-bar>

    <v-main>
      <dApp />
    </v-main>
    <v-footer app height="40px" flat color="transparent">
      <v-col class="text-center text-caption" cols="12">
        Powered by Airnode
      </v-col>
    </v-footer>
  </v-app>
</template>

<script>
import dApp from "./components/dApp";

export default {
  name: "App",

  components: {
    dApp,
  },

  data: () => ({
    //
  }),
  computed: {
    theme() {
      return this.$vuetify.theme.dark ? "dark" : "light";
    },
  },
};
</script>

<style></style>
