import { NextResponse, type NextRequest } from 'next/server'

/* The labs (/lab, /lab/*, and the public/lab hub) are local workbenches.
   In production they answer with the site's 404 page, so the code stays
   in the repo without the URLs existing publicly. Rewriting to a path no
   route owns is what makes Next render not-found.tsx with a 404 status. */
export function proxy(request: NextRequest) {
  if (process.env.NODE_ENV === 'production') {
    return NextResponse.rewrite(new URL('/__lab-not-found', request.url))
  }
}

export const config = {
  matcher: ['/lab', '/lab/:path*'],
}
