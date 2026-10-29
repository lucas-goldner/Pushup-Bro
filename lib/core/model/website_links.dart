enum WebsiteLinks {
  personalSite('lucas-goldner.com'),
  x('x.com/LucasGoldner'),
  privacyPolicy('apps-privacies-terms-lg.vercel.app/pushup-bro/privacy.html'),
  termsOfService(
    'apps-privacies-terms-lg.vercel.app/pushup-bro/terms-of-service.html',
  );

  const WebsiteLinks(this.link);
  final String link;
}
