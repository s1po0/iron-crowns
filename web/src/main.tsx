import React from "react";
import ReactDOM from "react-dom/client";
import {
  createRootRoute,
  createRoute,
  createRouter,
  RouterProvider,
} from "@tanstack/react-router";
import "@fontsource/vazirmatn/arabic-400.css";
import "@fontsource/vazirmatn/arabic-500.css";
import "@fontsource/vazirmatn/arabic-600.css";
import "@fontsource/vazirmatn/arabic-700.css";
import "./style.css";
import App from "./App";
import MapPage from "./routes/Map";
import CastlePage from "./routes/Castle";
import Party from "./routes/Party";
import Campaign from "./routes/Campaign";
import Market from "./routes/Market";
import Leaderboard from "./routes/Leaderboard";
import { Provider } from "./game/engine/store";
import { t } from "./i18n";
document.title = t.title;
const root = createRootRoute({
  component: App,
  notFoundComponent: () => <a href="/">{t.home}</a>,
});
const routes = [
  createRoute({
    getParentRoute: () => root,
    path: "/campaign",
    component: Campaign,
  }),
  createRoute({ getParentRoute: () => root, path: "/", component: MapPage }),
  createRoute({
    getParentRoute: () => root,
    path: "/castle",
    component: CastlePage,
  }),
  createRoute({ getParentRoute: () => root, path: "/party", component: Party }),
  createRoute({
    getParentRoute: () => root,
    path: "/market",
    component: Market,
  }),
  createRoute({
    getParentRoute: () => root,
    path: "/leaderboard",
    component: Leaderboard,
  }),
];
const router = createRouter({ routeTree: root.addChildren(routes) });
declare module "@tanstack/react-router" {
  interface Register {
    router: typeof router;
  }
}
ReactDOM.createRoot(document.getElementById("root")!).render(
  <React.StrictMode>
    <Provider>
      <RouterProvider router={router} />
    </Provider>
  </React.StrictMode>,
);
