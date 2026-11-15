# WireGuard TV — release

Pacchetti di **WireGuard TV**, client WireGuard ottimizzato per Amazon Fire TV e Android TV:
APK per Fire OS / Android TV e `.vpkg` per le Fire TV con **Vega OS** (es. Fire TV Stick 4K Select).
Questo repo contiene solo le release: il codice sorgente è privato.

## Installazione su Fire TV con Downloader

1. Installa l'app **Downloader** (AFTVnews) dall'Amazon Appstore.
2. Aprila e inserisci il codice:

   ## `9618861`

3. Conferma l'installazione. La prima volta Fire OS chiede di consentire
   *Installa app sconosciute* per Downloader.

Il codice scarica sempre l'ultima versione.

## Link diretto

https://github.com/tommy052201/wireguard-client-releases/releases/latest/download/wireguard-tv.apk

## Aggiornamenti

L'app controlla da sola le nuove release e mostra il pulsante **Aggiorna**
(oppure *Impostazioni → Cerca aggiornamenti*).

## Fire TV con Vega OS (es. Fire TV Stick 4K Select)

Le Fire TV con Vega OS non installano APK né usano Downloader: serve un pacchetto `.vpkg`, installato dal PC.
L'app è la stessa (schermate, logo, QR per importare dal telefono), con alcune funzioni in meno perché Vega non le
permette: avvio automatico all'accensione, esclusione di app dalla VPN, controllo da ADB e aggiornamento dall'app.

Pacchetti (ultima release):

- Fire TV Stick 4K Select: https://github.com/tommy052201/wireguard-client-releases/releases/latest/download/wireguard-tv-armv7.vpkg
- `wireguard-tv-aarch64.vpkg` e `wireguard-tv-x86_64.vpkg` per gli altri modelli Vega

### Installazione e aggiornamento da Windows

1. Sulla TV: *Impostazioni → La mia Fire TV → Opzioni sviluppatore*: attiva **Developer Mode** e imposta
   **Connection Mode = TCP/IP**.
2. Sul PC servono WSL (Ubuntu) con il **Vega SDK** installato (`~/vega`).
   La prima volta: `vega devmode login` e `vega devmode enable-device <codice mostrato dalla TV>`.
3. Scarica [`install-vega.ps1`](install-vega.ps1) ed esegui in PowerShell:

   ```powershell
   .\install-vega.ps1 -TvIp 192.168.1.37 -Launch
   ```

   Lo script scarica l'ultima versione e la installa. Per **aggiornare** si riesegue lo stesso comando: i tunnel
   salvati restano. Con `-Path file.vpkg` usa un pacchetto già scaricato.
4. Al primo avvio la TV chiede il consenso *aggiungere VPN*: accettalo.

Su Mac/Linux: `vega device install-app --packagePath wireguard-tv-armv7.vpkg --device <ip-tv>:5555`.

> Se il link dei `.vpkg` risponde 404, l'ultima release è stata pubblicata prima del supporto Vega: attendi la
> prossima build.
