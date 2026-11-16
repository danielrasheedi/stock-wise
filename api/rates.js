// Vercel function: GET /api/rates
// Returns USD exchange rates from ExchangeRate-API, using the key stored in
// Vercel's environment variables so it never appears in the app's code.
module.exports = async (req, res) => {
  res.setHeader('Content-Type', 'application/json; charset=utf-8');
  res.setHeader('Access-Control-Allow-Origin', '*'); // rates are public data

  const key = process.env.EXCHANGE_RATE_API_KEY;
  if (!key) {
    res.statusCode = 500;
    res.setHeader('Cache-Control', 'no-store');
    return res.end(JSON.stringify({ result: 'error', 'error-type': 'missing-key' }));
  }

  try {
    const upstream = await fetch(`https://v6.exchangerate-api.com/v6/${encodeURIComponent(key)}/latest/USD`);
    const data = await upstream.json();
    if (!upstream.ok || data.result !== 'success') {
      res.statusCode = 502;
      res.setHeader('Cache-Control', 'no-store');
      return res.end(JSON.stringify({ result: 'error', 'error-type': data['error-type'] || 'upstream' }));
    }
    // Same shape the app already reads; cached for an hour to save API calls
    res.statusCode = 200;
    res.setHeader('Cache-Control', 'public, s-maxage=3600, max-age=600');
    res.end(JSON.stringify({
      result: 'success',
      time_last_update_utc: data.time_last_update_utc,
      conversion_rates: data.conversion_rates,
    }));
  } catch (e) {
    res.statusCode = 502;
    res.setHeader('Cache-Control', 'no-store');
    res.end(JSON.stringify({ result: 'error', 'error-type': 'network' }));
  }
};
