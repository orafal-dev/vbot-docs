"use server"

import { eq } from "drizzle-orm"
import { revalidatePath } from "next/cache"
import { redirect } from "next/navigation"

import { getAdminUser } from "@/lib/auth"
import { requireDb } from "@/lib/db"
import { adminInvitations, scripts } from "@/lib/db/schema"
import { invitationFormSchema, scriptFormSchema } from "@/lib/validation"

const requireAdmin = async () => {
  const adminUser = await getAdminUser()
  if (!adminUser) throw new Error("Unauthorized admin operation.")
  return adminUser
}

const errorRedirect = (path: string, message: string): never =>
  redirect(`${path}?error=${encodeURIComponent(message)}`)
const parseScriptOrRedirect = (formData: FormData, errorPath: string) => {
  const parsed = scriptFormSchema.safeParse({
    title: formData.get("title"),
    slug: formData.get("slug") || formData.get("title"),
    description: formData.get("description"),
    code: formData.get("code"),
    published: formData.get("published") === "on",
  })

  if (parsed.success) {
    return parsed.data
  }

  return errorRedirect(
    errorPath,
    parsed.error.issues[0]?.message ?? "Invalid script."
  )
}
const parseInvitationOrRedirect = (formData: FormData) => {
  const parsed = invitationFormSchema.safeParse({
    email: formData.get("email"),
  })

  if (parsed.success) {
    return parsed.data
  }

  return errorRedirect(
    "/admin",
    parsed.error.issues[0]?.message ?? "Invalid email."
  )
}
const revalidatePublicLibrary = () => {
  revalidatePath("/")
  revalidatePath("/sitemap.xml")
}

export const createScript = async (formData: FormData) => {
  const adminUser = await requireAdmin()
  const data = parseScriptOrRedirect(formData, "/admin/scripts/new")
  try {
    await requireDb().insert(scripts).values({
      ...data,
      status: data.published ? "published" : "draft",
      authorId: adminUser.id,
      publishedAt: data.published ? new Date() : null,
    })
  } catch {
    errorRedirect("/admin/scripts/new", "Could not create script. The slug may already exist.")
  }
  revalidatePublicLibrary()
  revalidatePath("/admin")
  if (data.published) {
    revalidatePath(`/scripts/${data.slug}`)
  }
  redirect("/admin")
}

export const updateScript = async (id: string, formData: FormData) => {
  await requireAdmin()
  const data = parseScriptOrRedirect(formData, `/admin/scripts/${id}/edit`)
  const [existing] = await requireDb().select({ publishedAt: scripts.publishedAt })
    .from(scripts).where(eq(scripts.id, id)).limit(1)
  if (!existing) errorRedirect("/admin", "Script not found.")
  try {
    await requireDb().update(scripts).set({
      ...data,
      status: data.published ? "published" : "draft",
      publishedAt: data.published ? existing.publishedAt ?? new Date() : null,
    }).where(eq(scripts.id, id))
  } catch {
    errorRedirect(`/admin/scripts/${id}/edit`, "Could not save script. The slug may already exist.")
  }
  revalidatePublicLibrary()
  revalidatePath("/admin")
  revalidatePath(`/scripts/${data.slug}`)
  redirect("/admin")
}

export const deleteScript = async (id: string) => {
  await requireAdmin()
  const [existing] = await requireDb()
    .select({ slug: scripts.slug })
    .from(scripts)
    .where(eq(scripts.id, id))
    .limit(1)
  await requireDb().delete(scripts).where(eq(scripts.id, id))
  revalidatePublicLibrary()
  revalidatePath("/admin")
  if (existing?.slug) {
    revalidatePath(`/scripts/${existing.slug}`)
  }
}

export const createInvitation = async (formData: FormData) => {
  await requireAdmin()
  const data = parseInvitationOrRedirect(formData)
  const inserted = await requireDb().insert(adminInvitations).values({ email: data.email })
    .onConflictDoNothing().returning({ id: adminInvitations.id })
  if (inserted.length === 0) errorRedirect("/admin", "That email has already been invited.")
  revalidatePath("/admin")
  redirect("/admin?invited=1")
}
